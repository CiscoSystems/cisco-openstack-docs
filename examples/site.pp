#
# base variables and configuration shared by all!
#
# Comment out the following for "production", otherwise, you'll see every exec call from every puppet run, which can get a little overwhelming!
Exec { logoutput => true }

# Need our cobbler definitions
import "cobbler-node"

# Experimental.  Add a pre-define set of ssh keys to the root account.  This is really only useful for debug purposes, and is _NOT_ the right way to distribute remote access.
#import "ssh-keys"

#Build Server definition.
node /build-0/ inherits "cobbler-node" {

#change the servers for your NTP environment
  class { ntp:
    servers => [ "ntp.esl.cisco.com", "2.ntp.esl.cisco.com", "3.ntp.esl.cisco.com", ],
    ensure => running,
    autoupdate => true,
  }

# set up a local apt cache.  Eventually this may become a local mirror/repo instead
  class { apt-cacher-ng:
    }

# set the right local puppet environment up.  This builds puppetmaster with storedconfigs (and a local mysql instance)
  class { puppet:
    run_master => true,
    puppetmaster_address => $::ipaddress_eth0,
    mysql_password => 'ubuntu',	
  }
}

# base parameters for managed nodes (not necessarily the cobbler/puppetmaster node)
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

  class { puppet:
    run_agent => true,
    puppetmaster_address => "sdu-os-0.sdu.lab",
  }

  class { ntp:
    servers => [ "ntp.esl.cisco.com", "2.ntp.esl.cisco.com", "3.ntp.esl.cisco.com", ],
    ensure => running,
    autoupdate => true,
  }

# This will set up a test nova compute instance script. You need to manually run this if you want to run a quick test on one of the control nodes

  file { '/tmp/test_nova.sh':
    source => 'puppet:///modules/openstack/nova_test.sh',
  }

}

# variables related to the flat_DHCP environment

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

# controller for flat_DHCP
# NOTE: Change the floating_range
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
    export_resources        => false,
  }

}

#Build your compute nodes
node /compute-[1-9]/ inherits flat_dhcp {

#Needed to address a short term failure in nova-volume management - bug has been filed
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
# Default catch-all node definition
#

node default {
  notify { 'default_node': }
}


