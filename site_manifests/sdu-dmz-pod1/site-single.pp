#
# This document serves as an example of how to deploy
# basic single and multi-node openstack environments.
#

# deploy a script that can be used to test nova
class { 'openstack::test_file': }
# Load apt prerequisites.  This is only valid on Ubuntu systmes
class { 'apt': }
# Grab the Cisco-Openstack-Mirror code
# This assumes you installed the puppet code from the same mirror.
openstack::apt{"cisco-repo":
  location => 'ppa:cisco-openstack-mirror/cisco-proposed',
  key => '3BEFA739',
  key_source => 'hkp://keyserver.ubuntu.com:80/',
}

####### shared variables ##################


# this section is used to specify global variables that will
# be used in the deployment of multi and single node openstack
# environments

# assumes that eth0 is the public interface
$public_interface        = 'eth0'
# assumes that eth1 is the interface that will be used for the vm network
# this configuration assumes this interface is active but does not have an
# ip address allocated to it.
$private_interface       = 'eth0.201'
# credentials
$admin_email             = 'root@localhost'
$admin_password          = 'Cisco123'
$keystone_db_password    = 'keystone_db_pass'
$keystone_admin_token    = 'keystone_admin_token'
$nova_db_password        = 'nova_pass'
$nova_user_password      = 'nova_pass'
$glance_db_password      = 'glance_pass'
$glance_user_password    = 'glance_pass'
$rabbit_password         = 'openstack_rabbit_password'
$rabbit_user             = 'openstack_rabbit_user'
$fixed_network_range     = '10.0.0.0/24'
$floating_ip_range       = '192.168.200.96/27'
# switch this to true to have all service log at verbose
$verbose                 = 'false'
# by default it does not enable atomatically adding floating IPs
$auto_assign_floating_ip = true

# include and load swift config and node definitions:
import 'swift-nodes'

# Load the cobbler node defintios needed for the preseed of nodes
import 'cobbler-node'

# expot an authhorized keys file to the root user of all nodes.
# This is most useful for testing.
import 'ssh-keys'

#### end shared variables #################


node /build-os/ inherits "cobbler-node" {

#change the servers for your NTP environment
  class { ntp:
    servers => [ "192.168.200.1"],
    ensure => running,
    autoupdate => true,
  }

# set up a local apt cache.  Eventually this may become a local mirror/repo instead
  class { apt-cacher-ng:
    }

# set the right local puppet environment up.  This builds puppetmaster with storedconfigs (a nd a local mysql instance)
  class { puppet:
    run_master => true,
    puppetmaster_address => $::fqdn,
    certname => 'build-os.cc.lab',
    mysql_password => 'ubuntu',	
  }<-
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

$controller_node_address  = '192.168.200.41'

$controller_node_public   = $controller_node_address
$controller_node_internal = $controller_node_address
$sql_connection         = "mysql://nova:${nova_db_password}@${controller_node_internal}/nova"

#Common configuration for all node compute, controller, storage but puppet-master/cobbler
node base {
  #class { 'collectd':
  #}
}

node /control01/ inherits base {

#import "tempest_add"

#change the servers for your NTP environment
 class { ntp:
    servers => [ "192.168.200.1" ],
    ensure => running,
    autoupdate => true,
  }

  class { 'openstack::controller':
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_internal,
    floating_range          => $floating_ip_range,
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => true,
    # by default is assumes flat dhcp networking mode
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    verbose                 => $verbose,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    mysql_root_password     => $mysql_root_password,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    export_resources        => true,
  }


  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }
  

# configure the keystone service user and endpoint
  class { 'swift::keystone::auth':
    auth_name => $swift_user,
    password => $swift_user_password,
    address  => $swift_proxy_address,
  }

}

node /compute0/ inherits base {

#change the servers for your NTP environment
  class { ntp:
    servers => [ "3.ntp.esl.cisco.com", "5.ntp.esl.cisco.com", "7.ntp.esl.cisco.com", ],
    ensure => running,
    autoupdate => true,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }



  class { 'openstack::compute':
    public_interface   => $public_interface,
    private_interface  => $private_interface,
    internal_address   => $ipaddress_eth0,
    libvirt_type       => 'kvm',
    fixed_range        => $fixed_network_range,
    network_manager    => 'nova.network.manager.FlatDHCPManager',
    multi_host         => true,
    sql_connection     => $sql_connection,
    nova_user_password => $nova_user_password,
    rabbit_host        => $controller_node_internal,
    rabbit_password    => $rabbit_password,
    rabbit_user        => $rabbit_user,
    glance_api_servers => "${controller_node_internal}:9292",
    vncproxy_host      => $controller_node_public,
    vnc_enabled        => 'true',
    verbose            => $verbose,
    manage_volumes     => true,
    nova_volume        => 'nova-volumes'
  }

}

node default {
  notify{"Default Node: Perhaps add a node definition to site.pp": }
}
