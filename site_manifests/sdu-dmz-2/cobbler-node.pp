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

$cobbler_node_ip = "192.168.99.254"

node /cobbler-node/ {


 class { cobbler:
  node_subnet => '192.168.99.0',
  node_netmask => '255.255.255.0',
  node_gateway => '192.168.99.1',
  node_dns => "${cobbler_node_ip}",
  ip => "${cobbler_node_ip}",
  dns_service => 'dnsmasq',
  dhcp_service => 'dnsmasq',
  dhcp_ip_low => '192.168.99.50',
  dhcp_ip_high => '192.168.99.59',
  domain_name => 'sdu.lab',
  proxy => "http://${cobbler_node_ip}:3142/",
  password_crypted => '$6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1',
 }

# This will load the Ubuntu precise x86_64 server iso into cobbler
 cobbler::ubuntu { "precise":
 }

# This will build a preseed file called 'cisco-preseed' in /etc/cobbler/preseeds/
 cobbler::ubuntu::preseed { "cisco-preseed-ab":
  packages => "openssh-server vim vlan lvm2 ntp puppet",
  ntp_server => "192.168.100.1",
  late_command => '
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a server=os-build.sdu.lab" -i /target/etc/puppet/puppet.conf ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo -e "server 192.168.99.1 iburst\nserver 5.ntp.esl.cisco.com\nserver 7.ntp.esl.cisco.com" > /target/etc/ntp.conf ; \
echo "8021q" >> /target/etc/modules ; \
echo -e "# Private Interface\nauto eth0.98\niface eth0.98 inet manual\n\tvlan-raw-device eth0\n\tup ifconfig eth0.98 0.0.0.0 up\n" >> /target/etc/network/interfaces ; \
true
',
  proxy => "http://${cobbler_node_ip}:3142/",
  password_crypted => '$6$5NP1.NbW$WOXi0W1eXf9GOc0uThT5pBNZHqDH9JNczVjt9nzFsH7IkJdkUpLeuvBU.Zs9x3P6LBGKQh6b0zuR8XSlmcuGn.',
  expert_disk => true,
  diskpart => ['/dev/sdb'],
  boot_disk => '/dev/sda',
 }

# This will build a preseed file called 'cisco-preseed' in /etc/cobbler/preseeds/
 cobbler::ubuntu::preseed { "cisco-preseed":
  packages => "openssh-server vim vlan lvm2 ntp puppet",
  ntp_server => "192.168.100.1",
  late_command => '
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a server=os-build.sdu.lab" -i /target/etc/puppet/puppet.conf ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo -e "server 192.168.99.1 iburst\nserver 5.ntp.esl.cisco.com\nserver 7.ntp.esl.cisco.com" > /target/etc/ntp.conf ; \
echo "8021q" >> /target/etc/modules ; \
echo -e "# Private Interface\nauto eth0.98\niface eth0.98 inet manual\n\tvlan-raw-device eth0\n\tup ifconfig eth0.98 0.0.0.0 up\n" >> /target/etc/network/interfaces ; \
true
',
  proxy => "http://${cobbler_node_ip}:3142/",
  password_crypted => '$6$5NP1.NbW$WOXi0W1eXf9GOc0uThT5pBNZHqDH9JNczVjt9nzFsH7IkJdkUpLeuvBU.Zs9x3P6LBGKQh6b0zuR8XSlmcuGn.',
  expert_disk => true,
  diskpart => ['/dev/sdb'],
  boot_disk => '/dev/sda',
 }


# The following are node definitions that will allow cobbler to PXE boot the hypervisor OS onto the system (based on the preseed built above)
# You will want to adjust the "title" (maps to system name in cobbler), mac address (this is the PXEboot MAC target), IP (this is a static DHCP delivered address for this particular node), domain (added to /etc/resolv.conf for proper function), power address, the same one for power-strip based power control, per-node for IPMI/CIMC/ILO based control, power-ID needs to map to power port or service profile name (in UCSM based deployements)
cobbler::node { "control01":
 mac => "00:25:B5:0A:00:1E",
 profile => "precise-x86_64-auto",
 ip => "192.168.99.10",
 domain => "sdu.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed-ab",
 power_address => "192.168.26.15:org-SDU",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Sdu!12345",
 power_id => "SDU-OS-2-1",
 }

cobbler::node { "compute01":
 mac => "00:25:B5:0A:00:7D",
 profile => "precise-x86_64-auto",
 ip => "192.168.99.20",
 domain => "sdu.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.15:org-SDU",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Sdu!12345",
 power_id => "SDU-OS-2-2",
 }

cobbler::node { "compute02":
 mac => "00:25:B5:0A:00:5D",
 profile => "precise-x86_64-auto",
 ip => "192.168.99.21",
 domain => "sdu.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.15:org-SDU",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Sdu!12345",
 power_id => "SDU-OS-2-3",
 }

cobbler::node { "compute03":
 mac => "00:25:B5:0A:00:3D",
 profile => "precise-x86_64-auto",
 ip => "192.168.99.22",
 domain => "sdu.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.15:org-SDU",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Sdu!12345",
 power_id => "SDU-OS-2-3",
 }
# Repeat as necessary.
}
