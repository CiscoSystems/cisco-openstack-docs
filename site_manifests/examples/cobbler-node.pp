# = Cobbler and Puppet for nodes
#
# == Example
#
# add this to your site.pp file:
# import "cobbler-node"
# Default variables
# Cobbler IP network for DHCP
# 
$node_subnet = "192.168.100.0"
$node_netmask = "255.255.255.0"
$node_gateway = "192.168.100.1"
$cobbler_host_ip = '192.168.100.254'
$node_dns = $cobbler_host_ip
$domain_name = 'sdu.lab'
$dns_service = 'dnsmasq'
$dns_service = 'dnsmasq'
$http_proxy_URL = "http://${cobbler_host_ip}:3142/"
$password_crypted = '$6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1'


# A node definition for cobbler, note that it inherets ntp, just to make sure
# You will likely want ot change the name regex, either to match the FQDN, or
# to match an appropriate subset.
# You will likely also want to change the IP addresses, domain name, and perhaps
# even the proxy address
# If you are not using UCS blades, don't worry about the org-EXAMPLE, and if you are
# and aren't using an organization domain, just leave the value as ""
# An example MD5 crypted password is ubuntu: .DO/SOAPxKem.dRDx6UbyMd0HM6RQl1fxHYxPRuYFrRB04OcbO7c1
# which is used by the cobbler preseed file to set up the default admin user.
node /cobbler-node/ {

 class { cobbler:
  node_subnet => $node_subnet,
  node_netmask => $node_netmask,
  node_gateway => $node_gateway,
  node_dns => $node_dns,
  dns_service => $dns_service
  dhcp_service => $dhcp_service
  ip => $cobbler_host_ip,
  domain_name => $domain_name,
  proxy => $http_proxy_URL,
  password_crypted => $password_crypted,
 }

 cobbler::ubuntu { "precise":
 }

 cobbler::ubuntu::preseed { "cisco-preseed":
  packages => "openssh-server lvm2 ntp puppet",
  late_command => '
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo "server ${http_server} iburst" > /target/etc/ntp.conf ; \
echo "auto eth1" >> /target/etc/network/interfaces ; \
echo "iface eth1 inet loopback" >> /target/etc/network/interfaces
',
  proxy => 'http://192.168.100.254:3142/',
  password_crypted => '$6$5NP1.NbW$WOXi0W1eXf9GOc0uThT5pBNZHqDH9JNczVjt9nzFsH7IkJdkUpLeuvBU.Zs9x3P6LBGKQh6b0zuR8XSlmcuGn.', # ubuntu
  expert_disk => true,
  diskpart => ['/dev/sdc'],
  boot_disk => '/dev/sdc',
 }


# cobbler node definition, for "control node"
cobbler::node { "sdu-os-1":
 mac => "00:25:b5:00:00:08",
 profile => "precise-x86_64-auto",
 ip => "192.168.100.101",
 domain => "sdu.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.26.15:org-SDU",
 power_type => "ucs",
 power_user => "admin",
 power_password => "Sdu!12345",
 power_id => "SDU-OS-1",
 add_hosts_entry => true,
 extra_host_aliases => ["nova","keystone","glance","horizon"],
 }

# "compute" node, no additional aliases
cobbler::node { "sdu-os-2":
 mac => "00:25:b5:00:00:16",
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
}
