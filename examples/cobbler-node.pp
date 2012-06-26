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

$cobbler_node_ip = 192.168.100.254 

node /cobbler-node/ {


 class { cobbler:
  node_subnet => '192.168.100.0',
  node_netmask => '255.255.255.0',
  node_gateway => '192.168.100.1',
  node_dns => "${cobbler_node_ip}",
  ip => "${cobbler_node_ip}",
  dns_service => 'dnsmasq',
  dhcp_service => 'dnsmasq',
  dhcp_ip_low => '192.168.100.50',
  dhcp_ip_high => '192.168.100.59',
  domain_name => 'sdu.lab',
  proxy => "http://${cobbler_node_ip}:3142/",
  password_crypted => '$6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1',
 }

# This will load the Ubuntu precise x86_64 server iso into cobbler
 cobbler::ubuntu { "precise":
 }

# This will build a preseed file called 'cisco-preseed' in /etc/cobbler/preseeds/
 cobbler::ubuntu::preseed { "cisco-preseed":
  packages => "openssh-server lvm2 ntp puppet",
  late_command => '
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo "server ${http_server} iburst" > /target/etc/ntp.conf ; \
echo "auto eth1" >> /target/etc/network/interfaces ; \
echo "iface eth1 inet loopback" >> /target/etc/network/interfaces ; \
true
',
  proxy => "http://${cobbler_node_ip}:3142/",
  password_crypted => '$6$5NP1.NbW$WOXi0W1eXf9GOc0uThT5pBNZHqDH9JNczVjt9nzFsH7IkJdkUpLeuvBU.Zs9x3P6LBGKQh6b0zuR8XSlmcuGn.',
  expert_disk => true,
  diskpart => ['/dev/sdc'],
  boot_disk => '/dev/sdc',
 }


# The following are node definitions that will allow cobbler to PXE boot the hypervisor OS onto the system (based on the preseed built above)
# You will want to adjust the "title" (maps to system name in cobbler), mac address (this is the PXEboot MAC target), IP (this is a static DHCP delivered address for this particular node), domain (added to /etc/resolv.conf for proper function), power address, the same one for power-strip based power control, per-node for IPMI/CIMC/ILO based control, power-ID needs to map to power port or service profile name (in UCSM based deployements)
cobbler::node { "control-1":
 mac => "00:25:b5:00:00:01",
 profile => "precise-x86_64-auto",
 ip => "192.168.100.10",
 domain => "example.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.100.5:org-EXAMPLE",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Cisco123!",
 power_id => "CONTROL-1",
 }

cobbler::node { "compute-1":
 mac => "00:25:b5:00:01:01",
 profile => "precise-x86_64-auto",
 ip => "192.168.100.100",
 domain => "example.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.100.5:org-EXAMPLE",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Cisco123!",
 power_id => "COMPUTE-1",
 }
# Repeat as necessary.
}
