node default {
   notify { 'default_node': }
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

  $admin_email             = 'starmer@cisco.com'

  $public_interface        = 'eth0'
  $private_interface       = 'eth1'
  
  $fixed_range             = '10.0.0.0/16'

  $verbose                 = true

  # this is required to make concat work with PE
  file { '/var/lib/puppet':
    ensure => directory,
  }

  class { ntp:
    servers => [ "ntp.esl.cisco.com", "2.ntp.esl.cisco.com", "3.ntp.esl.cisco.com", ],
    ensure => running,
    autoupdate => true,
  }

  file { '/tmp/test_nova.sh':
    source => 'puppet:///modules/openstack/nova_test.sh',
  }

}

# variables related to the multi_host vlan environemnt
node multi_host_vlan inherits base {

  $controller_node_internal = '192.168.100.101'
  $controller_node_public   = '192.168.100.101' 
  $sql_connection           = "mysql://nova:${nova_db_password}@${controller_node_internal}/nova"
  $create_networks          = false

  class { 'openstack::auth_file': 
    admin_password       => $admin_password,
    keystone_admin_token => $admin_token, 
    controller_node      => $controller_node_internal,
  }

}

node flat_dhcp inherits base {

  $controller_node_internal = '192.168.100.101'
  $controller_node_public   = '192.168.100.101' 
  $sql_connection           = "mysql://nova:${nova_db_password}@${controller_node_internal}/nova"

  class { 'openstack::auth_file': 
    admin_password       => $admin_password,
    keystone_admin_token => $admin_token, 
    controller_node      => $controller_node_internal,
  }

}


