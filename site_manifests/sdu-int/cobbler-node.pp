node /cobbler-node/ {


# set up the cobbler instance on the "cobbler" node
 class { cobbler:
  node_subnet => "10.16.205.0",	# this is the IP domain
  node_netmask => "255.255.255.0",	# that the DHCP service
  node_gateway => "10.16.205.1",	# will use for cobbled
  node_dns => "10.16.205.60",		# nodes
  ip => '10.16.205.60',		# This is the "next-router" for PXE
  dhcp_ip_low => '10.16.205.70',
  dhcp_ip_high => '10.16.205.79',
  dns_service => 'dnsmasq', # choices dnsmasq, isc-bind-server
  dhcp_service => 'dnsmasq', # choices dnsmasq, isc-dhcp-server
  domain_name => "sdu.lab",		# This is the domain that matches DHCP
  proxy => "http://10.16.205.60:3142/",	# This  is the APT proxy (Debian specific)
  password_crypted => '$6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1',	# Default user (localadmin in preboot.erb) password.  "ubuntu" by default.
 }

 cobbler::ubuntu { "precise":	# Load via ubuntu-orchestra-import-isos "name"
 }

 cobbler::ubuntu::preseed { "cisco-preseed":
  packages => "openssh-server vlan lvm2 ntp puppet",
  late_command => '
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo "8021q" >> /target/etc/modules ; \
echo "server ${http_server} iburst" > /target/etc/ntp.conf ; \
echo -e "auto eth0.400\niface eth0.400 inet loopback\n\tvlan-raw-device eth0\n\tup ip link set eth0.400 promisc on" >> /target/etc/network/interfaces ; \
true
',
  proxy => 'http://10.16.205.60:3142/',
  password_crypted => '$6$5NP1.NbW$WOXi0W1eXf9GOc0uThT5pBNZHqDH9JNczVjt9nzFsH7IkJdkUpLeuvBU.Zs9x3P6LBGKQh6b0zuR8XSlmcuGn.',
  expert_disk => true,
  diskpart => ['/dev/sda'],
  boot_disk => '/dev/sda',
 }

# cobbler node definitions
  cobbler::node { "control-1":
    mac => "00:25:B5:00:05:BF",
    profile => "precise-x86_64-auto",
    ip => "10.16.205.61",
    domain => "sdu.lab",
    preseed => "/etc/cobbler/preseeds/cisco-preseed",
    power_address => "10.16.205.20",
    power_type => "ucs",
    power_user => "admin",
    power_password => "Ciscoese123",
    power_id => "SDU-OS-2",
    boot_disk => "/dev/sda",
  }
  cobbler::node { "compute-1":
    mac => "00:25:B5:00:05:AF",
    profile => "precise-x86_64-auto",
    ip => "10.16.205.62",
    domain => "sdu.lab",
    preseed => "/etc/cobbler/preseeds/cisco-preseed",
    power_address => "10.16.205.20",
    power_type => "ucs",
    power_user => "admin",
    power_password => "Ciscoese123",
    power_id => "SDU-OS-3",
    boot_disk => "/dev/sda",
  }
  cobbler::node { "compute-2":
    mac => "00:25:B5:00:05:9F",
    profile => "precise-x86_64-auto",
    ip => "10.16.205.63",
    domain => "sdu.lab",
    preseed => "/etc/cobbler/preseeds/cisco-preseed",
    power_address => "10.16.205.20",
    power_type => "ucs",
    power_user => "admin",
    power_password => "Ciscoese123",
    power_id => "SDU-OS-4",
    boot_disk => "/dev/sda",
  }

}
