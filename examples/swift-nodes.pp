$swift_user_password  = 'swift_pass'
$swift_shared_secret     = '7?3&hfhs9:)2'
$swift_local_net_ip      = $ipaddress_eth0

node /keystone/ {
  class { 'swift::keystone::auth':
    password          => $swift_user_password,
    address           => $controller_node_public,
  }
  
#  include role_swift_proxy

}

# Class to caputre the creation of xfs based file system on physical devices

class swift-ucs-rack {

  filesystem {  '/dev/sdd':
    ensure => present,
    fs_type => 'xfs',
  }

  filesystem {  '/dev/sde':
    ensure => present,
    fs_type => 'xfs',
  }

}
# Class to capture the creation of two LVM based volume groups
class swift-ucs-blade-lvm {

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

# Already have a VG with space for a second lv?
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

node /swift-stor-1/ {

  include swift-ucs-blades-lvm
  $swift_zone = 1
  include role_swift_storage

}

node /swift-stor-2/ {

  include swift-ucs-blades-lvm
  $swift_zone = 2
  include role_swift_storage

}
node /swift-stor-3/ {

  include swift-ucs-blades-lvm
  $swift_zone = 3
  include role_swift_storage

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

  #swift::storage::mount { 'nova--volumes-swift--lv--1':
  #  device       => '/dev/mapper/nova--volumes-swift--lv--1',
  #  mnt_base_dir => '/srv/node',
  #  require      => Class['swift'],
  #}
  #swift::storage::mount { 'nova--volumes-swift--lv--2':
  #  device       => '/dev/mapper/nova--volumes-swift--lv--2',
  #  mnt_base_dir => '/srv/node',
  #  require      => Class['swift'],
  #}


  swift::storage::mount { 'swift-d1':
    device       => '/dev/sdd1',
    mnt_base_dir => '/srv/node',
    require      => Class['swift'],
  }
    
  swift::storage::mount { 'swift-d2':
    device       => '/dev/sde1',
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
