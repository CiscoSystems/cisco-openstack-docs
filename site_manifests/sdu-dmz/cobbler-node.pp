# = Cobbler and Puppet for nodes
#
# == Example
#
# add this to your site.pp file:
# import "cobbler-node"

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

# class { puppet:
#  run_master => true,
#  puppetmaster_address => "sdu-os-0.sdu.lab",
# }

 class { cobbler:
  node_subnet => "192.168.100.0",
  node_netmask => "255.255.255.0",
  node_gateway => "192.168.100.1",
  node_dns => "192.168.26.186",
  ip => '192.168.100.254',
  dns_service => 'dnsmasq',
  dhcp_service => 'dnsmasq',
  dhcp_ip_low => '192.168.100.50',
  dhcp_ip_high => '192.168.100.59',
  domain_name => "sdu.lab",
  proxy => "http://192.168.100.254:3142/",
  password_crypted => '$6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1',
 }

 cobbler::ubuntu { "precise":
 }

 cobbler::ubuntu::preseed { "cisco-preseed":
  packages => "openssh-server vlan lvm2 ntp puppet",
  early_command => 'dd if=/dev/zero of=/dev/sda count=1000 bs=1M',
  late_command => '
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo "8021q" >> /target/etc/modules ; \
echo "server ${http_server} iburst" > /target/etc/ntp.conf ; \
echo "auto eth0.400" >> /target/etc/network/interfaces ; \
echo "iface eth0.400 inet loopback" >> /target/etc/network/interfaces ; \
echo "   vlan-raw-device eth0" >> /target/etc/network/interfaces
',
  proxy => 'http://192.168.100.254:3142/',
  password_crypted => '$6$5NP1.NbW$WOXi0W1eXf9GOc0uThT5pBNZHqDH9JNczVjt9nzFsH7IkJdkUpLeuvBU.Zs9x3P6LBGKQh6b0zuR8XSlmcuGn.',
  expert_disk => true,
  diskpart => ['/dev/sda'],
  boot_disk => '/dev/sda',
 }


# cobbler node definitions
cobbler::node { "sdu-os-1":
 mac => "00:25:B5:0A:00:5F",
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

cobbler::node { "sdu-os-2":
 mac => "00:25:B5:0A:00:3F",
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

cobbler::node { "sdu-os-3":
 mac => "00:25:B5:0A:00:1F",
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

cobbler::node { "sdu-os-4":
 mac => "00:25:B5:0A:00:7E",
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

cobbler::node { "sdu-os-5":
 mac => "00:25:B5:0A:00:5E",
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

cobbler::node { "sdu-os-6":
 mac => "00:25:B5:0A:00:3E",
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
}
