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
# import "ssh-keys"

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

#  class { 'role_swift_ringbuilder': }

#  class { 'role_swift_proxy':
#    require => Class['role_swift_ringbuilder'],
#  }

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


