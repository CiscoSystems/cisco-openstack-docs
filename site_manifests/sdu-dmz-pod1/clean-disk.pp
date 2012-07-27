file { '/tmp/clean_disk.sh':
  ensure => present,
  mode => 0755,
  source => 'puppet:///files/clean_disk.sh',
}

