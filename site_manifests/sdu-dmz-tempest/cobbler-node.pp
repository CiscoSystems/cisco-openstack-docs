# = Cobbler and Puppet for nodes
#
# == Example
#
# add this to your site.pp file:
# import "cobbler-node"
# in your site.pp file, add a node definition like:
# node 'cobbler.example.com' inherits cobbler-node { }
#

# A node definition for cobbler
# You will likely also want to change the IP addresses, domain name, and perhaps
# even the proxy address
# If you are not using UCS blades, don't worry about the org-EXAMPLE, and if you are
# and aren't using an organization domain, just leave the value as ""
# An example MD5 crypted password is ubuntu: $6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1
# which is used by the cobbler preseed file to set up the default admin user.

$cobbler_node_ip = "192.168.200.254"

node /cobbler-node/ {


 class { cobbler:
  node_subnet => '192.168.200.0',
  node_netmask => '255.255.255.0',
  node_gateway => '192.168.200.1',
  node_dns => "${cobbler_node_ip}",
  ip => "${cobbler_node_ip}",
  dns_service => 'dnsmasq',
  dhcp_service => 'dnsmasq',
  dhcp_ip_low => '192.168.200.240',
  dhcp_ip_high => '192.168.200.250',
  domain_name => 'cc.lab',
  proxy => "http://${cobbler_node_ip}:3142/",
  password_crypted => '$6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1',
 }

# This will load the Ubuntu precise x86_64 server iso into cobbler
 cobbler::ubuntu { "precise":
 }

# This will build a preseed file called 'cisco-preseed' in /etc/cobbler/preseeds/
 cobbler::ubuntu::preseed { "cisco-preseed":
  packages => "openssh-server vim vlan lvm2 ntp puppet",
  ntp_server => "192.168.200.1",
  late_command => '
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a server=build-os.cc.lab" -i /target/etc/puppet/puppet.conf ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo -e "server 192.168.200.1 iburst\nserver 5.ntp.esl.cisco.com\nserver 7.ntp.esl.cisco.com" > /target/etc/ntp.conf ; \
echo "8021q" >> /target/etc/modules ; \
echo -e "# Private Interface\nauto eth0.201\niface eth0.201 inet manual\n\tvlan-raw-device eth0\n\tup ifconfig eth0.201 0.0.0.0 up\n" >> /target/etc/network/interfaces ; \
true
',
  proxy => "http://${cobbler_node_ip}:3142/",
  password_crypted => '$6$5NP1.NbW$WOXi0W1eXf9GOc0uThT5pBNZHqDH9JNczVjt9nzFsH7IkJdkUpLeuvBU.Zs9x3P6LBGKQh6b0zuR8XSlmcuGn.',
  expert_disk => true,
  diskpart => ['/dev/sdc'],
  boot_disk => '/dev/sdc',
 }

 cobbler::ubuntu::preseed { "cisco-preseed-a":
  packages => "openssh-server vim vlan lvm2 ntp puppet",
  ntp_server => "172.25.249.21",
  late_command => '
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a server=build-os.sdu.lab" -i /target/etc/puppet/puppet.conf ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo -e "server 192.168.200.1 iburst\nserver 5.ntp.esl.cisco.com\nserver 7.ntp.esl.cisco.com" > /target/etc/ntp.conf ; \
echo "8021q" >> /target/etc/modules ; \
echo -e "# Private Interface\nauto eth0.201\niface eth0.201 inet manual\n\tvlan-raw-device eth0\n\tup ifconfig eth0.201 0.0.0.0 up\n" >> /target/etc/network/interfaces ; \
true
',
  proxy => "http://${cobbler_node_ip}:3142/",
  password_crypted => '$6$5NP1.NbW$WOXi0W1eXf9GOc0uThT5pBNZHqDH9JNczVjt9nzFsH7IkJdkUpLeuvBU.Zs9x3P6LBGKQh6b0zuR8XSlmcuGn.',
  expert_disk => true,
  diskpart => ['/dev/sda'],
  boot_disk => '/dev/sda',
 }

# The following are node definitions that will allow cobbler to PXE boot the hypervisor OS onto the system (based on the preseed built above)
# You will want to adjust the "title" (maps to system name in cobbler), mac address (this is the PXEboot MAC target), IP (this is a static DHCP delivered address for this particular node), domain (added to /etc/resolv.conf for proper function), power address, the same one for power-strip based power control, per-node for IPMI/CIMC/ILO based control, power-ID needs to map to power port or service profile name (in UCSM based deployements)

cobbler::node { "control01":
 mac => "A4:4C:11:13:22:E2",
 profile => "precise-x86_64-auto",
 ip => "192.168.200.40",
 domain => "cc.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.200.2",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

cobbler::node { "compute01":
 mac => "A4:4C:11:13:98:21",
 profile => "precise-x86_64-auto",
 ip => "192.168.200.20",
 domain => "cc.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.200.4",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

cobbler::node { "compute02":
 mac => "A4:4C:11:13:64:4A",
 profile => "precise-x86_64-auto",
 ip => "192.168.200.21",
 domain => "cc.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.200.5",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

cobbler::node { "swiftproxy01":
 mac => "E8:B7:48:4D:CB:17",
 profile => "precise-x86_64-auto",
 ip => "192.168.200.50",
 domain => "cc.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.200.6",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

cobbler::node { "swift01":
 mac => "A4:4C:11:13:57:71",
 profile => "precise-x86_64-auto",
 ip => "192.168.200.30",
 domain => "cc.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.200.7",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

cobbler::node { "swift02":
 mac => "A4:4C:11:13:9C:E4",
 profile => "precise-x86_64-auto",
 ip => "192.168.200.31",
 domain => "cc.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.200.8",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

cobbler::node { "swift03":
 mac => "A4:4C:11:13:93:FF",
 profile => "precise-x86_64-auto",
 ip => "192.168.200.32",
 domain => "cc.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.200.9",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

# Repeat as necessary.
}
