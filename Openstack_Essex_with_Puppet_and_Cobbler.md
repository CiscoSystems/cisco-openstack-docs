OpenStack Essex with Puppet and Cobbler
=======================================

This document discusses the deployment of the OpenStack software components in a non-HA environment in a multi-node model.  It does not currently cover the infrastructure setup and configuration, which will be covered in the infrastructure reference design.

Current Outstanding Tasks
-------------------------

* add cobbler "default" enlist PXE boot preseed & profile
* complete documented walkthrough deploment
* document a script/package based deployment

Install Baseline OS on the deployment node
------------------------------------------

Eventually we may build out an ISO for this, but to begin, we need a node onto which we build everything else. We have done our first pass of this deployment with Canonical's Ubuntu distribution, due to the fact that this solution seems to have a stable package model for deploying the Essex release components.

([http://releases.ubuntu.com/precise/]), x86_64 server edition

Update this OS
--------------
something you should do often with Ubuntu based distributions


	sudo apt-get update
	sudo apt-get dist-upgrade -y

Get Puppet and Git
==================

Create an ssh key for your user:

	mkdir ~/puppet-ssh && ssh-keygen -t rsa -N "" -f ~/puppet-ssh/id_rsa
	
	sudo apt-get install puppetmaster git ipmitool rails mysql-server ruby-mysql ruby-dbd-mysql libmysql-ruby libmysqlclient-dev ruby-activerecord -y
	sudo gem install mysql -- --with-mysql-config=/usr/bin/mysql_config

assuming your default mysql user is root, and the password is ubuntu

	mysql -uroot -pubuntu -e"create database puppet;grant all privileges on puppet.* to puppet@localhost identified by 'puppet';"

	cat >> /etc/puppet/puppet.conf <<EOF
	storeconfigs = true
	dbadapter = mysql
	dbuser = puppet
	dbpassword = puppet
	dbserver = localhost
	dbsocket = /var/run/mysqld/mysqld.sock
	EOF


Reboot the node, or restart puppetmaster:

	sudo /etc/init.d/puppetmaster stop
	sudo /etc/init.d/puppetmaster start

If you are behind a proxy, the following may help:

	cat >> /etc/environment <<EOF
	http_proxy='http://user:pass@proxy.example.com:8080'
	https_proxy='https://user:pass@proxy.example.com:8080'
	EOF

You may also want to set up apt-cacher-ng:

	apt-get install apt-cacher-ng

And then fix the Proxy config if necessary:

	echo "Proxy: http://user:pass@proxy.example.com:8080" >> /etc/apt-cacher-ng/acng.conf

And re-start acng just for good measure:

	/etc/init.d/apt-cacher-ng restart

A nice value add, point your browser to http://cobbler-node.example.com:3142/acng-report.html

Grab the puppetlabs openstack modules:

	git clone https://github.com/puppetlabs/puppetlabs-openstack /etc/puppet/modules/openstack

In order to download the rest of the pieces, we'll leverage the Rakefile included in the repo:

	cd /etc/puppet/modules/openstack
	sed -e 's/^\(.*checkout_branches:.*\)/#\1/' -i /etc/puppet/modules/openstack/other_repos.yaml
	sed -e 's/^\# modulepath/modulepath/' -i /etc/puppet/modules/openstack/other_repos.yaml
	sed -e 's/git\:/https:/' -i /etc/puppet/modules/openstack/other_repos.yaml 
	cat >> other_repos.yaml <<EOF
	    https://github.com/CiscoSystems/puppet-cobbler: cobbler
	    https://github.com/puppetlabs/puppetlabs-ntp: ntp
	EOF
	sudo rake modules:clone

That "cat inplace" file adds two modules not in dan@puppetlabs current repository model.

Now, go edit the /etc/puppet/manifests/site.pp file.

`

	# Uncomment to get logged output from Exec commands.
	# This generates lots of data so should not normally be used in production.
	# Exec { logoutput => true }

	# If you are using cobbler to build a base image, import the cobbler definitions
	# You can then run "puppet apply site.pp" to build and update the cobbler environment
	# There is a built-in assumption that the puppetmaster and cobbler nodes are the same node
	# Imports both cobbler and puppetmaster baseline installs.
	import "cobbler-node"

	# This is a hack that will distribute a ssh public and private key to all root instances
	# Really only used if you're constantly jumping between systems for debug purposes
	# I'm also sure there's a much better way to do this.
	# WARNING. This is currently applied to _all_ nodes as it is just a set of root level
	# puppet file resources.
	# import "ssh_keys"

	node /cobbler/ inherits "cobbler-node" {

		class { ntp:
		  servers => [ "ntp.esl.cisco.com", "2.ntp.esl.cisco.com", "3.ntp.esl.cisco.com", ],
		  ensure => running,
		  autoupdate => true,
		}

	}

	node base {

	  $rabbit_user             = 'rabbit_user'
	  $rabbit_password         = 'rabbit_password'
	  $nova_db_password        = 'nova_db_password'
	  $keystone_db_password    = 'keystone_db_password'
	  $glance_db_password      = 'glance_db_password'
	  $sql_connection          = "mysql://nova:${nova_db_password}@${controller_node_internal}/nova"
	  $admin_password          = 'admin_password'
	  $admin_token             = 'admin_token'
	  $mysql_root_password     = 'sql_pass' 

	  $nova_service_password   = 'nova_pass'
	  $glance_service_password = 'glance_pass'

	  $admin_email             = 'admin@example.com'

	  $public_interface        = 'eth0'
	  $private_interface       = 'eth1'
  
	  $fixed_range             = '10.0.0.0/16'

	  $verbose                 = true

	  class { ntp:
	    servers => [ "ntp.esl.cisco.com", "2.ntp.esl.cisco.com", "3.ntp.esl.cisco.com", ],
	    ensure => running,
	    autoupdate => true,
	  }

	  class { puppet:
	    run_agent => true,
	    puppetmaster_address => "sdu-os-0.sdu.lab",
	  }

	  file { '/tmp/test_nova.sh':
	    source => 'puppet:///modules/openstack/nova_test.sh',
	  }

	}

	# variables related to the multi_host vlan environemnt

	node flat_dhcp inherits base {

	# NOTE: CHANGE THESE ADDRESSES

	  $controller_node_internal = '192.168.100.101'
	  $controller_node_public   = '192.168.100.101' 
	  $sql_connection           = "mysql://nova:${nova_db_password}@${controller_node_internal}/nova"

	  class { 'openstack::auth_file': 
	    admin_password       => $admin_password,
	    keystone_admin_token => $admin_token, 
	    controller_node      => $controller_node_internal,
	  }

	}

	# controller for multi-host with DHCP
	node /sdu-os-1/ inherits flat_dhcp {

	  class { 'nova::volume':
	    enabled => true,
	  }

	  class { 'nova::volume::iscsi': }

	# NOTE: CHANGE THE ADDRESS POOL

	  class { 'openstack::controller':
	    public_address          => $controller_node_public,
	    public_interface        => $public_interface,
	    private_interface       => $private_interface,
	    internal_address        => $controller_node_internal,
	    floating_range          => '192.168.100.64/28',
	    fixed_range             => $fixed_range,
	    multi_host              => false,
	    network_manager         => 'nova.network.manager.FlatDHCPManager',
	    verbose                 => $verbose,
	    mysql_root_password     => $mysql_root_password,
	    admin_email             => $admin_email,
	    admin_password          => $admin_password,
	    keystone_db_password    => $keystone_db_password,
	    keystone_admin_token    => $admin_token,
	    glance_db_password      => $glance_db_password,
	    glance_service_password => $glance_service_password,
	    nova_db_password        => $nova_db_password,
	    nova_service_password   => $nova_service_password,
	    rabbit_password         => $rabbit_password,
	    rabbit_user             => $rabbit_user,
	  }

	}
	node /sdu-os-[2-3]/ inherits flat_dhcp {

	  class { 'nova::compute::file_hack': }

	  class { 'openstack::compute':
	    private_interface  => $private_interface,
	    internal_address   => $ipaddress_eth0,
	    glance_api_servers => "${controller_node_internal}:9292",
	    rabbit_host        => $controller_node_internal,
	    rabbit_password    => $rabbit_password,
	    rabbit_user        => $rabbit_user,
	    sql_connection     => $sql_connection,
	    vncproxy_host      => $controller_node_internal,
	    verbose            => $verbose,
	    manage_volumes     => true,
	 }

	}

	node default {
	  notify { 'default_node': }
	}



`

We can add the following into /etc/puppet/manifests/cobbler-node.pp

`

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


	# And an NTP nodes class that can be used in other descriptions.  This updates the 
	# default NTP server added via cobbler (if used for node deployments)
	# NOTE: Puppet gets unhappy if NTP is out of sync. 
	node ntp_nodes {
	  class { ntp:
	    servers => [ "ntp.esl.cisco.com", "2.ntp.esl.cisco.com", "3.ntp.esl.cisco.com", ],
	    ensure => running,
	    autoupdate => true,
	  }
	}

	# A node definition to make sure that puppet points to the puppet master for your 
	# cloud.  Likely you will want to change the name here as well (by default puppet
	# will look for "puppet", this adds the FQDN instead)
	# Also note, this inhereits ntp again
	node cloud_nodes inherits ntp_nodes { 
	  class { puppet:
	    run_agent => true,
	    puppetmaster_address => "sdu-os-0.sdu.lab",
	  }
	}

	# A node definition for cobbler, note that it inherets ntp, just to make sure
	# You will likely want ot change the name regex, either to match the FQDN, or
	# to match an appropriate subset.
	# You will likely also want to change the IP addresses, domain name, and perhaps
	# even the proxy address
	# If you are not using UCS blades, don't worry about the org-EXAMPLE, and if you are
	# and aren't using an organization domain, just leave the value as ""
	# An example MD5 crypted password is ubuntu: .DO/SOAPxKem.dRDx6UbyMd0HM6RQl1fxHYxPRuYFrRB04OcbO7c1
	# which is used by the cobbler preseed file to set up the default admin user.
	node /cobbler-node/ inherits ntp_nodes {

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


`

run puppet locally to sync the cobbler instance:
	sudo puppet apply -v -t /etc/puppet/manifests/site.pp

If you have cobbler set, you can also use my "clean up" script to re-set a node if things didn't go right, or you just want to start from almost scratch (assuming you're not rebuilding the puppet node as well):


	cat > clean_node.sh <<EOF
	#!/bin/bash
	domain="sdu.lab"
	sudo cobbler system edit --name=$1 --netboot-enable=Y
	sudo cobbler system poweroff --name=$1
	sudo cobbler system poweron --name=$1
	sudo puppet cert clean $1.$domain
	sudo ssh-keygen -R $1
	EOF
	chmod +x clean_node.sh


Enable cobbler to build the rest of your nodes
----------------------------------------------

If your cobber-node.pp file was configured properly, you also have the rest of your nodes added to cobbler

Boot the rest of your nodes
---------------------------

This assumes they are listed in your cobbler-node.pp file as well

	cobbler system poweron --name={system_name}

or
	for n in name1 name2 name3; do cobbler system poweron --name=$n; done

Now, let's see if OpenStack is working.
---------------------------------------

First, if you didn't just use the defaults, and perhaps used VLAN rather than FlatDHCP networks, you need to create a network:

	source openrc
	nova-manage network create --label vlan1 --fixed_range_v4 10.0.1.0/24 --num_networks 1 --network_size 256 --vlan 

If you don't have an openrc, then you really need to find out what your site.pp user/tenant/password you need, but these are the defaults:

	cat > openrc <<EOF
	  export OS_TENANT_NAME=openstack
	  export OS_USERNAME=admin
	  export OS_PASSWORD=admin_password
	  export OS_AUTH_URL="http://192.168.100.101:5000/v2.0/"
	  export OS_AUTH_STRATEGY=keystone
	  export SERVICE_TOKEN=admin_token
	  export SERVICE_ENDPOINT=http://192.168.100.101:35357/v2.0/
	EOF

Then, we should be able to follow the basic instructions here:

[http://docs.openstack.org/trunk/openstack-compute/admin/content/booting-a-test-image.html]

Although there are many image choices, including an ubuntu 12.04 beta:
[http://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64.tar.gz].  If you do grab this image, you will need to add the root file system, initrd, and kernel as separate files, which is not covered hre.

	wget https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img

	name=cirros-0.3-x86_64
	image=cirros-0.3.0-x86_64-disk.img
	glance add name=$name is_public=true container_format=bare disk_format=qcow2 < $image

Let's make sure the image uploaded properly:

	glance index

Ok, so we have an image, and a network.

Next, we need to add a public key to the system so that it can be injected into the image. This will allow us to log into the deployed image.

	nova keypair-add test > test.pem
	chmod 600 test.pem

Now we can start the boot process:

	sudo nova boot --image cirros-0.3.0-x86_64 --flavor m1.small --key_name test my-first-server

So your server should now be booting, which you can check on with:

	nova list

Once it's booted, you can login (grab the IP from the output of nova list):

	ssh -i test.pem -l cirros $ipaddress

If your ssh password cert doesn't work, you can try the cirros user password: cubswin:-)

