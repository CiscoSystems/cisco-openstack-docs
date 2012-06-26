#
# base variables and configuration shared by all!
#
# Comment out the following for "production", otherwise, you'll see every exec call from every puppet run, which can get a little overwhelming!
Exec { logoutput => true }

# Need our cobbler definitions
import "cobbler-node"
import "ssh-keys"
# Add the swift definitions
import "swift-nodes"

# Experimental.  Add a pre-define set of ssh keys to the root account.  This is really only useful for debug purposes, and is _NOT_ the right way to distribute remote access.
# If you want, you can enable ssh authorized_keys distribution from an authorized_keys file stored in /etc/puppet/files by default.  NOTE: YOU WILL OVERWRITE ROOT's authorized_keys ON ALL NODES WITH THIS, INCLUDING THE PUPPETMASTER NODE!
#import "ssh-keys"

#Build Server definition.
node /osmgmt-ch2-a01/ inherits "cobbler-node" {

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

  file {'/etc/puppet/files':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0755',
  }
  
  file {'/etc/puppet/fileserver.conf':
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => '
# This file consists of arbitrarily named sections/modules
# defining where files are served from and to whom

# Define a section "files"
# Adapt the allow/deny settings to your needs. Order
# for allow/deny does not matter, allow always takes precedence
# over deny
[files]
  path /etc/puppet/files
  allow *
#  allow *.example.com
#  deny *.evil.example.com
#  allow 192.168.0.0/24

[plugins]
#  allow *.example.com
#  deny *.evil.example.com
#  allow 192.168.0.0/24
',
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
  $mysql_root_password     = 'ubuntu' 

  $nova_user_password      = 'nova_pass'
  $glance_user_password    = 'glance_pass'

  $admin_email             = 'admin@example.com'

  $public_interface        = 'eth0'
  $private_interface       = 'eth0.110'
 
  $fixed_range             = '10.0.0.0/16'

# swift specific configurations
  $swift_user           = 'swift'
  $swift_user_password  = 'swift_pass'
  $swift_shared_secret  = 'Gdr8ny7YyWqy2'
  $swift_local_net_ip   = $ipaddress_eth0
  $swift_proxy_address    = '192.168.100.107'

  $verbose                 = true

  class { puppet:
    run_agent => true,
    puppetmaster_address => "osmgmt-ch2-a01.sdu.lab",
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

# variables related to Multi_Host_VLAN Network Mode

node multi_host_vlan inherits base {

  $controller_node_internal = '192.168.100.104'
  $controller_node_public   = '192.168.100.104'
  $sql_connection           = "mysql://nova:${nova_db_password}@${controller_node_internal}/nova"
  $create_networks	    = true

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $admin_token,
    controller_node      => $controller_node_internal,
  }

}

# variables related to the flat_DHCP environment

node flat_dhcp inherits base {

  $controller_node_internal = '192.168.100.104'
  $controller_node_public   = '192.168.100.104' 
  $sql_connection           = "mysql://nova:${nova_db_password}@${controller_node_internal}/nova"

  class { 'openstack::auth_file': 
    admin_password       => $admin_password,
    keystone_admin_token => $admin_token, 
    controller_node      => $controller_node_internal,
  }

}

# controller for flat_DHCP
# NOTE: Change the floating_range
node /sdu-os-4/ inherits flat_dhcp {

  class { 'openstack::controller':
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_internal,
    floating_range          => '192.168.100.64/28',
    fixed_range             => $fixed_range,
    multi_host              => true,
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    verbose                 => $verbose,
    mysql_root_password     => $mysql_root_password,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $admin_token,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    export_resources        => false,
#    cache_server_ip         => '127.0.0.1',
#    cache_server_port       => '11211',
#    swift                   => true,
#    quantum                 => true,
#    horizon_app_links	    => '[ ["Nagios","http://nagios:8808"],["Ganglia","http://ganglia:1123/graphite"],["Statsd","http://stats"] ]',
  }

  class {'branding': }

# configure the keystone service user and endpoint
  class { 'swift::keystone::auth':
    auth_name => $swift_user,
    password => $swift_user_password,
    address  => $swift_proxy_address,
  }

}

#Build your compute nodes
node /sdu-os-vlan-node/ inherits multi_host_vlan {

#Needed to address a short term failure in nova-volume management - bug has been filed
  class { 'nova::compute::file_hack': }

  class { 'openstack::compute':
    private_interface  => $private_interface,
    public_interface   => $public_interface,
    fixed_range        => $fixed_range,
    network_manager    => 'nova.network.manager.VlanManager',    
    internal_address   => $ipaddress_eth0,
    glance_api_servers => "${controller_node_internal}:9292",
    rabbit_host        => $controller_node_internal,
    rabbit_password    => $rabbit_password,
    rabbit_user        => $rabbit_user,
    sql_connection     => $sql_connection,
    vncproxy_host      => $controller_node_internal,
    verbose            => $verbose,
    multi_host         => true,
    manage_volumes     => true,
    vnc_enabled        => true,
    libvirt_type       => 'kvm',
 }

}


#
# Default catch-all node definition
#
node /sdu-os-[5-6]/ inherits flat_dhcp {

#Needed to address a short term failure in nova-volume management - bug has been filed
  class { 'nova::compute::file_hack': }

  class { 'openstack::compute':
    private_interface  => $private_interface,
#    public_interface   => $public_interface,
    internal_address   => $ipaddress_eth0,
    libvirt_type       => 'kvm',
    glance_api_servers => "${controller_node_internal}:9292",
    rabbit_host        => $controller_node_internal,
    rabbit_password    => $rabbit_password,
    rabbit_user        => $rabbit_user,
    sql_connection     => $sql_connection,
    vncproxy_host      => $controller_node_internal,
    verbose            => $verbose,
    network_manager    => 'nova.network.manager.FlatDHCPManager',
#    multi_host         => true,
    manage_volumes     => true,
 }

}

#
# Default catch-all node definition
#

node default {
  notify { 'default_node': }
}


