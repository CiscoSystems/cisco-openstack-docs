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
# $vlan_id = '105'
$cobbler_node_ip = '192.168.100.254'

node /cobbler-node/ {

# class { puppet:
#  run_master => true,
#  puppetmaster_address => "sdu-os-0.sdu.lab",
# }

 class { cobbler:
  node_subnet => "192.168.100.0",
  node_netmask => "255.255.255.0",
  node_gateway => "192.168.100.1",
  node_dns => "${cobbler_node_ip}",
  ip => "${cobbler_node_ip}",
  dns_service => 'dnsmasq',
  dhcp_service => 'dnsmasq',
  dhcp_ip_low => '192.168.100.50',
  dhcp_ip_high => '192.168.100.59',
  domain_name => "sdu.lab",
  proxy => "http://${cobbler_node_ip}:3142",
  password_crypted => '$6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1',
 }

# This will load the Ubuntu precise x86_64 server iso into cobbler
 cobbler::ubuntu { "precise":
 }

# This will build a preseed file called 'cisco-preseed' in /etc/cobbler/preseeds/
 cobbler::ubuntu::preseed { "cisco-preseed":
  packages => "vim openssh-server vlan lvm2 ntp puppet",
  late_command => '
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a server=osmgmt-ch2-a01.sdu.lab" -i /target/etc/puppet/puppet.conf ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo "server ${http_server} iburst" > /target/etc/ntp.conf
echo "8021q" >> /target/etc/modules ; \
echo -e "# Public Interface\nauto eth0.105\niface eth0.105 inet dhcp\n\tvlan-raw-device eth0n\tup ifconfig eth0.105 0.0.0.0 up\n\tup ip link set eth0.105 promisc on" >> /target/etc/network/interfaces ; \
echo -e "# Private Interface\nauto eth0.110\niface eth0.110 inet manual\n\tvlan-raw-device eth0\n\tup ifconfig eth0.110 0.0.0.0 up\n\tup ip link set eth0.110 promisc on" >> /target/etc/network/interfaces ; \
true
',
  proxy => "http://${cobbler_node_ip}:3142",
  password_crypted => '$6$5NP1.NbW$WOXi0W1eXf9GOc0uThT5pBNZHqDH9JNczVjt9nzFsH7IkJdkUpLeuvBU.Zs9x3P6LBGKQh6b0zuR8XSlmcuGn.',
  expert_disk => true,
  diskpart => ['/dev/sda'],
  boot_disk => '/dev/sda',
 }


# The following are node definitions that will allow cobbler to PXE boot the hypervisor OS onto the system (based on the preseed built above)
# You will want to adjust the "title" (maps to system name in cobbler), mac address (this is the PXEboot MAC target), IP (this is a static DHCP delivered address for this particular node), domain (added to /etc/resolv.conf for proper function), power address, the same one for power-strip based power control, per-node for IPMI/CIMC/ILO based control, power-ID needs to map to power port or service profile name (in UCSM based deployements)

# 

# Disk config: 1x600
cobbler::node { "sdu-os-1":
 mac => "00:25:B5:0A:00:7F",
 profile => "precise-x86_64-auto",
 ip => "192.168.100.101",
 domain => "sdu.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.15:org-SDU",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Sdu!12345",
 power_id => "SDU-OS-1",
 }

# Disk config: 1x600
cobbler::node { "sdu-os-2":
 mac => "00:25:B5:0A:00:5F",
 profile => "precise-x86_64-auto",
 ip => "192.168.100.102",
 domain => "sdu.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.15:org-SDU",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Sdu!12345",
 power_id => "SDU-OS-2",
 }

# Disk config: 1x600
cobbler::node { "sdu-os-3":
 mac => "00:25:B5:0A:00:3F",
 profile => "precise-x86_64-auto",
 ip => "192.168.100.103",
 domain => "sdu.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.15:org-SDU",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Sdu!12345",
 power_id => "SDU-OS-3",
 }

# Disk config: 2x146
cobbler::node { "sdu-os-4":
 mac => "00:25:B5:0A:00:1F",
 profile => "precise-x86_64-auto",
 ip => "192.168.100.104",
 domain => "sdu.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.15:org-SDU",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Sdu!12345",
 power_id => "SDU-OS-4",
 }


# Disk config: 2x300 striped
cobbler::node { "sdu-os-5":
 mac => "00:25:B5:0A:00:7E",
 profile => "precise-x86_64-auto",
 ip => "192.168.100.105",
 domain => "sdu.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.15:org-SDU",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Sdu!12345",
 power_id => "SDU-OS-5",
 }

# Disk config: 2x300 striped
cobbler::node { "sdu-os-6":
 mac => "00:25:B5:0A:00:5E",
 profile => "precise-x86_64-auto",
 ip => "192.168.100.106",
 domain => "sdu.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.15:org-SDU",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Sdu!12345",
 power_id => "SDU-OS-6",
 }

# Disk config: 2x146 striped
cobbler::node { "sdu-os-7":
 mac => "00:25:B5:0A:00:3E",
 profile => "precise-x86_64-auto",
 ip => "192.168.100.107",
 domain => "sdu.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.15:org-SDU",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Sdu!12345",
 power_id => "SDU-OS-7",
 }

}

