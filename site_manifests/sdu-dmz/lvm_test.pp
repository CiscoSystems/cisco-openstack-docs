include lvm

class lvm::volume {'/var/lib/libvirt':
  vg => 'nova-volume',
  pv => '/dev/sdc',
  fstype => 'ext4',
  size => '30%FREE'
  ensure => 'present',
}
