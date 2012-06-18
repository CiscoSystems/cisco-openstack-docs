#Exec { logoutput => true }
#
# base variables and configuration shared by all!
#
import "cobbler-node"
import "ssh-keys"

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
  }
}


node base {

  $rabbit_user             = 'rabbit_user'
  $rabbit_password         = 'rabbit_password'
  $nova_db_password        = 'nova_db_password'
  $keystone_db_password    = 'keystone_db_password'
  $glance_db_password      = 'glance_db_password'
  $admin_password          = 'admin_password'
  $admin_token             = 'keystone_token'
  $mysql_root_password     = 'sql_pass' 

  $nova_user_password   = 'nova_pass'
  $glance_user_password = 'glance_pass'
  $swift_user_password  = 'swift_pass'

  $admin_email             = 'admin@sdu.lab'

  $public_interface        = 'eth0'
  $private_interface       = 'eth0.400'

  $nova_volume             = 'nova-volumes'
  
  $fixed_range             = '10.0.0.0/16'

  $verbose                 = true

  # swift specific configurations
  $swift_shared_secret     = '7?3&hfhs9:)2'
  $swift_local_net_ip      = $ipaddress_eth0

  class { ntp:
    servers => [ "ntp.esl.cisco.com", "2.ntp.esl.cisco.com", "3.ntp.esl.cisco.com", ],
    ensure => running,
    autoupdate => true,
  }

  file { '/tmp/test_nova.sh':
    source => 'puppet:///modules/openstack/nova_test.sh',
  }

  package { 'vim':
    ensure => present
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


node /sdu-os-1/ inherits flat_dhcp {

  class { 'nova::volume': enabled => true }

  class { 'nova::volume::iscsi': }

  class { 'openstack::controller':
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_internal,
    floating_range          => '192.168.100.64/28',
    fixed_range             => $fixed_range,
#    multi_host              => true,
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
    cache_server_ip         => '127.0.0.1',
    cache_server_port       => '11211',
    swift                   => true,
#    quantum                 => true,
#    horizon_app_links	    => '[ ["Nagios","http://nagios:8808"],["Ganglia","http://ganglia:1123/graphite"],["Statsd","http://stats"] ]',
  }

  class { 'swift::keystone::auth':
    password          => $swift_user_password,
    address           => $controller_node_public,
  }
  
  include role_swift_proxy

#  class { 'tempest':
#    identity_host     => 'localhost',
#    image_host        => 'localhost',
#    admin_username    => 'admin',
#    admin_password    => $admin_password,
#    admin_tenant_name => 'openstack',
#  }

}

class swift-ucs-blades-lvs {

# Already have a VG with space?
  logical_volume { 'swift-lv-1':
    ensure => present,
    size => '100GB',
    volume_group => 'nova-volumes',
  } 

  filesystem { '/dev/nova-volumes/swift-lv-1':
   ensure => present,
   fs_type => 'xfs',
   require => Logical_volume['swift-lv-1'],
  }

# Already have a VG with space?
  logical_volume { 'swift-lv-2':
    ensure => present,
    size => '100GB',
    volume_group => 'nova-volumes',
  } 

  filesystem { '/dev/nova-volumes/swift-lv-2':
   ensure => present,
   fs_type => 'xfs',
   require => Logical_volume['swift-lv-2'],
  }

}

node /sdu-os-2/ inherits flat_dhcp {

  include swift-ucs-blades-lvs
  $swift_zone = 3
  include role_swift_storage


}
node /sdu-os-3/ inherits flat_dhcp {

  include swift-ucs-blades-lvs
  $swift_zone = 1
  include role_swift_storage

}
node /sdu-os-4/ inherits flat_dhcp {

  include swift-ucs-blades-lvs
  $swift_zone = 2
  include role_swift_storage

}

node /sdu-os-5/ inherits flat_dhcp {

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

  class { 'nova::compute::file_hack': }

}

node /sdu-os-6/ inherits flat_dhcp {

#  include role_swift_proxy

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

  class { 'nova::compute::file_hack': }


}

# classes that are used for role assignment

class role_swift  {

  class { 'ssh::server::install': }

  class { 'swift':
    # not sure how I want to deal with this shared secret
    swift_hash_suffix => $swift_shared_secret,
    package_ensure => latest,
  }
  
}

class role_swift_storage inherits role_swift {

  # create xfs partitions on a loopback device and mount them
  #swift::storage::loopback { ['1', '2']:
  #  base_dir     => '/srv/loopback-device',
  #  mnt_base_dir => '/srv/node',
  #  require      => Class['swift'],
  #}

  file {'/srv/node':
   ensure => directory,
   mode => '0777',
   owner => 'root',
   group => 'root',
  }
  swift::storage::mount { 'nova--volumes-swift--lv--1':
    device       => '/dev/mapper/nova--volumes-swift--lv--1',
    mnt_base_dir => '/srv/node',
    require      => Class['swift'],
  }
  swift::storage::mount { 'nova--volumes-swift--lv--2':
    device       => '/dev/mapper/nova--volumes-swift--lv--2',
    mnt_base_dir => '/srv/node',
    require      => Class['swift'],
  }

  # install all swift storage servers together
  class { 'swift::storage::all':
    storage_local_net_ip => $swift_local_net_ip,
  }

  # TODO I need to wrap these in a define so that
  # mcollective can collect that define

  # these implementation currently only allows a single device per endpoint
  # it will have to be resolved before release
  @@ring_object_device { "${swift_local_net_ip}:6000/1":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_object_device { "${swift_local_net_ip}:6000/2":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift_local_net_ip}:6001/1":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift_local_net_ip}:6001/2":
    zone        => $swift_zone,
    weight      => 1,
  }
  # TODO should device be changed to volume
  @@ring_account_device { "${swift_local_net_ip}:6002/1":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift_local_net_ip}:6002/2":
    zone        => $swift_zone,
    weight      => 1,
  }

  # sync ring databases if they have been exported
  Swift::Ringsync<<||>>

}

# node that installs a swift proxy
# you will probably have to run twice!

class role_swift_proxy inherits role_swift {

  # curl is only required so that I can run tests
  # package { 'curl': ensure => present }

#  class { 'memcached':
#    listen_ip => '127.0.0.1',
#  }

  class { 'swift::proxy':
    proxy_local_net_ip => $swift_local_net_ip,
    pipeline           => [
      'catch_errors',
      'healthcheck',
      'cache',
      'ratelimit',
      'swift3',
      's3token',
      'authtoken',
      'keystone',
      'proxy-server'
    ],
    account_autocreate => true,
    # TODO where is the  ringbuilder class?
    require            => Class['swift::ringbuilder'],
  }

  class { [
    'swift::proxy::catch_errors',
    'swift::proxy::healthcheck',
    'swift::proxy::cache',
    'swift::proxy::swift3',
  ]: }

  class { 'swift::proxy::ratelimit':
    clock_accuracy         => 1000,
    max_sleep_time_seconds => 60,
    log_sleep_time_seconds => 0,
    rate_buffer_seconds    => 5,
    account_ratelimit      => 0
  }

  class { 'swift::proxy::s3token':
    # assume that the controller host is the swift api server
    auth_host     => $controller_node_public,
    auth_port     => '35357',
  }

  class { 'swift::proxy::keystone':
    operator_roles => ['admin', 'SwiftOperator'],
  }

  class { 'swift::proxy::authtoken':
    admin_user        => 'swift',
    admin_tenant_name => 'services',
    admin_password    => $swift_user_password,
    # assume that the controller host is the swift api server
    auth_host         => $controller_node_public,
  }
 
  # collect all of the resources that are needed
  # to rebalance the ring
  Ring_object_device <<| |>>
  Ring_container_device <<| |>>
  Ring_account_device <<| |>>

  class { 'swift::ringbuilder':
    # the part power should be determined by assuming 100 partitions per drive
    part_power     => '18',
    replicas       => '3',
    min_part_hours => 1,
    require        => Class['swift'],
  }

  # sets up an rsync db that can be used to sync the ring DB
  class { 'swift::ringserver':
    local_net_ip => $swift_local_net_ip,
  }

  # exports rsync gets that can be used to sync the ring files
  @@swift::ringsync { ['account', 'object', 'container']:
    ring_server => $swift_local_net_ip
  }

  file { '/tmp/swift_keystone_test.rb':
    source => 'puppet:///modules/swift/swift_keystone_test.rb'
  }
}

node default {
  notify { 'default_node': }
}
