# This document serves as an example of how to deploy
# basic single and multi-node openstack environments.
#

# Switch this to false after your first run to prevent unsafe operations
# from potentially running again
$initial_setup           = true


# deploy a script that can be used to test nova
class { 'openstack::test_file': }
# Load apt prerequisites.  This is only valid on Ubuntu systmes
class { 'apt': }
# Grab the Cisco-Openstack-Mirror code
# This assumes you installed the puppet code from the same mirror.
#openstack::apt{"cisco-repo":
#  location => 'ppa:cisco-openstack-mirror/cisco-proposed',
#  key => '3BEFA739',
#  key_source => 'hkp://keyserver.ubuntu.com:80/',
#}

apt::ppa { 'ppa:cisco-openstack-mirror/cisco-proposed': }
apt::ppa { 'ppa:cisco-openstack-mirror/cisco': }

Apt::Ppa['ppa:cisco-openstack-mirror/cisco-proposed'] -> Package<| title != 'python-software-properties' |>
Apt::Ppa['ppa:cisco-openstack-mirror/cisco'] -> Package<| title != 'python-software-properties' |>


####### shared variables ##################
# this section is used to specify global variables that will
# be used in the deployment of multi and single node openstack
# environments
$multi_host		= true
# By default, corosync uses multicasting. It is possible to disable
# this if your environment require it
$corosync_unicast        = true
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
$glance_on_swift         = 'true'
$rabbit_password         = 'openstack_rabbit_password'
$rabbit_user             = 'openstack_rabbit_user'
$fixed_network_range     = '10.0.0.0/24'
$floating_ip_range       = '192.168.200.96/27'
# switch this to true to have all service log at verbose
$verbose                 = 'false'
# by default it does not enable atomatically adding floating IPs
$auto_assign_floating_ip = true
# Swift addresses:
$swift_proxy_address    = 'swiftproxy'
#### end shared variables #################

# multi-node specific parameters

# The address services will attempt to connect to the controller with
$controller_node_address       = '192.168.200.40'
$controller_node_public        = $controller_node_address
$controller_node_internal      = $controller_node_address

# The hostname other nova nodes see the controller as
$controller_hostname           = 'control'

# The actual address of the primary/active controller
$controller_node_primary       = '192.168.200.41'
$controller_hostname_primary   = 'control01'

# The actual address of the secondary/passive controller
$controller_node_secondary     = '192.168.200.42'
$controller_hostname_secondary = 'control02'

# The bind address for corosync. Should match the subnet the controller
# nodes use for the actual IP addresses
$controller_node_network       = '192.168.200.0'

$sql_connection = "mysql://nova:${nova_db_password}@${controller_node_address}/nova"

# /etc/hosts entries for the controller nodes
host { $controller_hostname_primary:
  ip => $controller_node_primary
}
host { $controller_hostname_secondary:
  ip => $controller_node_secondary
}
host { $controller_hostname:
  ip => $controller_node_internal
}
####
# Active and passive nodes are mostly configured identically.
# There are only two places where the configuration is different:
# whether openstack::controller is flagged as enabled, and whether
# $ha_primary is set to true on openstack_admin::controller::ha
####

# include and load swift config and node definitions:
import 'swift-nodes'

# Load the cobbler node defintios needed for the preseed of nodes
import 'cobbler-node'

# expot an authhorized keys file to the root user of all nodes.
# This is most useful for testing.
import 'ssh-keys'
import 'clean-disk'
#Common configuration for all node compute, controller, storage but puppet-master/cobbler
node base {
 class { ntp:
    servers => [ "192.168.200.1" ],
    ensure => running,
    autoupdate => true,
  }
}

node compute_base inherits base {
#  class { 'collectd':
#  }
}

node /control01/ inherits base {

import "glance_import"
#import "tempest_add"
# create DRBD logical volume.
  logical_volume { 'drbd-openstack':
    ensure       => present,
    volume_group => 'nova-volumes',
    size         => '152M',
  }

  class { 'openstack::controller':
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_internal,
    floating_range          => $floating_ip_range,
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => $multi_host,
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
    glance_on_swift         => $glance_on_swift,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    export_resources        => false,
    enabled                 => true, #different between active and passive.
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }

  class { 'openstack_admin::controller::ha':
    public_address      => $controller_node_public,
    public_interface    => $public_interface,
    internal_address    => $controller_node_internal,
    internal_interface  => $public_interface,
    primary_hostname    => $controller_hostname_primary,
    secondary_hostname  => $controller_hostname_secondary,
    controller_hostname => $controller_hostname,
    primary_address     => $controller_node_primary,
    secondary_address   => $controller_node_secondary,
    ha_primary          => true, # Different between active and passive
    volume_group        => 'nova-volumes',
    logical_volume      => 'drbd-openstack',
    corosync_address    => $controller_node_network,
    multi_host          => $multi_host,
    corosync_unicast    => $corosync_unicast,
    initial_setup       => $initial_setup,
  }

# configure the keystone service user and endpoint
  class { 'swift::keystone::auth':
    auth_name => $swift_user,
    password => $swift_user_password,
    address  => $swift_proxy_address,
  }

}

node /control02/ inherits base {

#import "tempest_add"
# create DRBD logical volume.
  logical_volume { 'drbd-openstack':
    ensure       => present,
    volume_group => 'nova-volumes',
    size         => '152M',
  }

  class { 'openstack::controller':
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_internal,
    floating_range          => $floating_ip_range,
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => $multi_host,
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
    glance_on_swift         => $glance_on_swift,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    export_resources        => false,
    enabled                 => false, #different between active and passive.
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }

  class { 'openstack_admin::controller::ha':
    public_address      => $controller_node_public,
    public_interface    => $public_interface,
    internal_address    => $controller_node_internal,
    internal_interface  => $public_interface,
    primary_hostname    => $controller_hostname_primary,
    secondary_hostname  => $controller_hostname_secondary,
    controller_hostname => $controller_hostname,
    primary_address     => $controller_node_primary,
    secondary_address   => $controller_node_secondary,
    ha_primary          => false, # Different between active and passive
    volume_group        => 'nova-volumes',
    logical_volume      => 'drbd-openstack',
    corosync_address    => $controller_node_network,
    multi_host          => $multi_host,
    corosync_unicast    => $corosync_unicast,
    initial_setup       => $initial_setup,
  }

# configure the keystone service user and endpoint
#  class { 'swift::keystone::auth':
#    auth_name => $swift_user,
#    password => $swift_user_password,
#    address  => $swift_proxy_address,
#  }
 
}

node /compute0/ inherits compute_base {

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
    multi_host         => $multi_host,
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
    nova_volume        => 'nova-volumes',
  }

}

node /build-os/ inherits "cobbler-node" {
 
  #import "glance_download"

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
    certname => 'build-os.dmz-pod1.lab',
    mysql_password => 'ubuntu',
  }<-
  file {'/etc/puppet/files':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0755',
  }

  exec {'echo "192.168.200.61 swiftproxy.dmz-lab1.lab swiftproxy\n192.168.200.62 swiftproxy.dmz-lab1.lab swiftproxy" >> /etc/hosts':
    cwd => '/tmp',
    path => ['/bin','/usr/bin'],
    unless => 'grep "swiftproxy.dmz-lab1.lab" /etc/hosts',
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
node default {
  notify{"Default Node: Perhaps add a node definition to site.pp": }
}
