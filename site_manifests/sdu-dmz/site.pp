#
# base variables and configuration shared by all!
#
Exec { logoutput => true }

import "cobbler-node"
import "ssh-keys"

#include "lvm"

node /sdu-os-0/ inherits "cobbler-node" {

  class { ntp:
    servers => [ "ntp.esl.cisco.com", "2.ntp.esl.cisco.com", "3.ntp.esl.cisco.com", ],
    ensure => running,
    autoupdate => true,
  }

  class { apt-cacher-ng:
    }

  class { puppet:
    run_master => true,
    puppetmaster_address => $::ipaddress_eth0,
    mysql_password => 'ubuntu',	
    domain => 'sdu.lab',
  }
}

node base {

#  include nagios::target

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

  $admin_email             = 'dan@puppetlabs.com'

  $public_interface        = 'eth0'
  $private_interface       = 'eth1'
  
  $fixed_range             = '10.0.0.0/16'

  $multi_host		   = false
  $verbose                 = true

  # this is a dmz specific hack
  #include cisco_dmz
  #include ssh

  #exec { "networking-refresh":
  #  command     => "/sbin/ifup eth1",
  #  #refreshonly => "true",
  #}

  # this is required to make concat work with PE
  #file { '/var/lib/puppet':
  #  ensure => directory,
  #}

  class { puppet:
    run_agent => true,
    puppetmaster_address => "sdu-os-0.sdu.lab",
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

# controller for multi-host with DHCP
node /sdu-os-1/ inherits flat_dhcp {

  class { 'nova::volume':
    enabled => true,
  }

  class { 'nova::volume::iscsi': }


  class { 'openstack::controller':
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_internal,
    floating_range          => '192.168.100.64/28',
    fixed_range             => $fixed_range,
    multi_host              => $multi_host,
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
    export_resources        => false,
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

#
# all in one examples
#

node default {
  notify { 'default_node': }
}


