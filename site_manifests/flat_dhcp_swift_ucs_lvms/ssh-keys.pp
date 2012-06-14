File {
  owner => 'root',
  group => 'root',
}

file { ssh_root_path:
  name => '/root/.ssh',
  ensure => directory,
  mode => 0600,
}

file { 'authorized_keys':
 ensure => present,
 name => '/root/.ssh/authorized_keys',
 mode => 0600,
 require => File['ssh_root_path'],
 source => 'puppet:///files/authorized_keys',
}
