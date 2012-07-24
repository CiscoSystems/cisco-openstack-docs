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

$cobbler_node_ip = "192.168.25.254"

node /cobbler-node/ {


 class { cobbler:
  node_subnet => '192.168.25.0',
  node_netmask => '255.255.255.0',
  node_gateway => '192.168.25.1',
  node_dns => "${cobbler_node_ip}",
  ip => "${cobbler_node_ip}",
  dns_service => 'dnsmasq',
  dhcp_service => 'dnsmasq',
  dhcp_ip_low => '192.168.25.120',
  dhcp_ip_high => '192.168.25.128',
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
  ntp_server => "192.168.25.1",
  late_command => '
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a server=os-build.sdu.lab" -i /target/etc/puppet/puppet.conf ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo -e "server 192.168.25.1 iburst\nserver 5.ntp.esl.cisco.com\nserver 7.ntp.esl.cisco.com" > /target/etc/ntp.conf ; \
echo "8021q" >> /target/etc/modules ; \
echo -e "# Private Interface\nauto eth0.400\niface eth0.400 inet manual\n\tvlan-raw-device eth0\n\tup ifconfig eth0.400 0.0.0.0 up\n" >> /target/etc/network/interfaces ; \
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
echo -e "server 192.168.25.1 iburst\nserver 5.ntp.esl.cisco.com\nserver 7.ntp.esl.cisco.com" > /target/etc/ntp.conf ; \
echo "8021q" >> /target/etc/modules ; \
echo -e "# Private Interface\nauto eth0.400\niface eth0.400 inet manual\n\tvlan-raw-device eth0\n\tup ifconfig eth0.400 0.0.0.0 up\n" >> /target/etc/network/interfaces ; \
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
 mac => "00:25:B5:00:00:BF",
 profile => "precise-x86_64-auto",
 ip => "192.168.25.10",
 domain => "dmz25.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.240",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Ciscoese123",
 power_id => "SDU-OS-2",
 }

cobbler::node { "compute01":
 mac => "00:25:B5:00:00:AF",
 profile => "precise-x86_64-auto",
 ip => "192.168.25.20",
 domain => "dmz25.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.240",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Ciscoese123",
 power_id => "SDU-OS-3",
 }

cobbler::node { "compute02":
 mac => "00:25:B5:00:00:9F",
 profile => "precise-x86_64-auto",
 ip => "192.168.25.21",
 domain => "dmz25.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.240",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Ciscoese123",
 power_id => "SDU-OS-4",
 }

cobbler::node { "compute03":
 mac => "00:25:B5:00:00:7F",
 profile => "precise-x86_64-auto",
 ip => "192.168.25.22",
 domain => "dmz25.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.240",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Ciscoese123",
 power_id => "SDU-OS-5",
 }

cobbler::node { "compute04":
 mac => "00:25:B5:00:00:5F",
 profile => "precise-x86_64-auto",
 ip => "192.168.25.23",
 domain => "dmz25.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.240",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Ciscoese123",
 power_id => "SDU-OS-6",
 }

cobbler::node { "compute05":
 mac => "00:25:B5:00:00:3F",
 profile => "precise-x86_64-auto",
 ip => "192.168.25.24",
 domain => "dmz25.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.240",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Ciscoese123",
 power_id => "SDU-OS-7",
 }

cobbler::node { "compute06":
 mac => "00:25:B5:00:00:1F",
 profile => "precise-x86_64-auto",
 ip => "192.168.25.25",
 domain => "dmz25.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.240",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Ciscoese123",
 power_id => "SDU-OS-8",
 }

cobbler::node { "compute07":
 mac => "00:25:B5:00:00:DE",
 profile => "precise-x86_64-auto",
 ip => "192.168.25.26",
 domain => "dmz25.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.240",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Ciscoese123",
 power_id => "SDU-OS-9",
 }

cobbler::node { "compute08":
 mac => "00:25:B5:00:00:BE",
 profile => "precise-x86_64-auto",
 ip => "192.168.25.27",
 domain => "dmz25.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.240",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Ciscoese123",
 power_id => "SDU-OS-10",
 }

cobbler::node { "compute09":
 mac => "00:25:B5:00:00:AE",
 profile => "precise-x86_64-auto",
 ip => "192.168.25.28",
 domain => "dmz25.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.240",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Ciscoese123",
 power_id => "SDU-OS-11",
 }

cobbler::node { "compute10":
 mac => "00:25:B5:00:00:9E",
 profile => "precise-x86_64-auto",
 ip => "192.168.25.29",
 domain => "dmz25.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.240",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Ciscoese123",
 power_id => "SDU-OS-12",
 }

cobbler::node { "compute11":
 mac => "00:25:B5:00:00:7E",
 profile => "precise-x86_64-auto",
 ip => "192.168.25.30",
 domain => "dmz25.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.240",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Ciscoese123",
 power_id => "SDU-OS-13",
 }

cobbler::node { "compute12":
 mac => "00:25:B5:00:00:5E",
 profile => "precise-x86_64-auto",
 ip => "192.168.25.31",
 domain => "dmz25.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.240",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Ciscoese123",
 power_id => "SDU-OS-14",
 }

cobbler::node { "compute13":
 mac => "00:25:B5:00:00:9E",
 profile => "precise-x86_64-auto",
 ip => "192.168.25.32",
 domain => "dmz25.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.240",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Ciscoese123",
 power_id => "SDU-OS-15",
 }


}
