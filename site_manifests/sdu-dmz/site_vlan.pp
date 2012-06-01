#
# base variables and configuration shared by all!
#
Exec { logoutput => true }

import "cobbler-node"
import "ssh_keys"

#include "lvm"

node /sdu-os-0/ inherits "cobbler-puppetmaster" {
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

  $admin_email             = 'dan@puppetlabs.com'

  $public_interface        = 'eth0'
  $private_interface       = 'eth1'
  
  $fixed_range             = '10.0.0.0/16'

  $verbose                 = true

  # this is a dmz specific hack
  #include cisco_dmz
  #include ssh

  #exec { "networking-refresh":
  #  command     => "/sbin/ifup eth1",
  #  #refreshonly => "true",
  #}

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

# controller for multi-host
node /sdu-os-1/ inherits multi_host_vlan {

  class { 'openstack::controller':
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_internal,
    floating_range          => '192.168.100.64/28',
    fixed_range             => $fixed_range,
    num_networks            => 3,
    create_networks         => $create_networks,
    multi_host              => true,
    network_manager         => 'nova.network.manager.VlanManager',
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

node /sdu-os-2/ inherits multi_host_vlan {

  # TODO make vlan start explicit
  class { 'openstack::compute':
    public_interface   => $public_interface,
    private_interface  => $private_interface,
    fixed_range        => $fixed_range,
    network_manager    => 'nova.network.manager.VlanManager',
    internal_address   => $ipaddress_eth0,
    glance_api_servers => "${controller_node_internal}:9292",
    rabbit_host        => $controller_node_internal,
    rabbit_password    => $rabbit_password,
    rabbit_user        => $rabbit_user,
    sql_connection     => $sql_connection,
    vncproxy_host      => $controller_node_internal,
    vnc_enabled        => true,
    libvirt_type       => 'kvm',
    multi_host         => true,
    verbose            => $verbose,
  }

}

$swift_shared_secret='09e96d0623cb5623'
$swift_local_net_ip = $ipaddress_eth0


node /sdu-os-3/ {

  class { 'role_swift_ringbuilder': }

  class { 'role_swift_proxy':
    require => Class['role_swift_ringbuilder'],
  }
}

import "swift_models"


node /sdu-os-4/ {

  $swift_zone = 1
  include role_swift_storage

}
node /sdu-os-5/ {

  $swift_zone = 2
  include role_swift_storage

}

node /sdu-os-7/ {
  
  $swift_zone = 3
  include role_swift_storage

}

#
# all in one examples
#

node default {
  notify { 'default_node': }
}

