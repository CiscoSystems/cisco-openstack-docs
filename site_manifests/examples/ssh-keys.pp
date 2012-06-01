File {
  owner => 'root',
  group => 'root',
}

file { ssh_root_path:
  name => '/root/.ssh',
  ensure => directory,
  mode => 0600,
}

file { 'id_rsa':
 ensure => present,
 name => '/root/.ssh/id_rsa',
 mode => 0600,
 require => File['ssh_root_path'],
 source => '/root/puppet-ssh/id_rsa',
}

file { 'id_rsa.pub':
 ensure => present,
 name => '/root/.ssh/id_rsa.pub',
 mode => 0600,
 require => File['ssh_root_path'],
 source => '/root/puppet-ssh/id_rsa.pub',
}


file { 'authorized_keys':
 ensure => present,
 name => '/root/.ssh/authorized_keys',
 mode => 0600,
 require => File['ssh_root_path'],
 content => '/root/puppet-ssh/authorized_keys',
}
