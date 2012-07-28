$gl_release = 'precise'
$gl_image_name = "${gl_release}-server-cloudimg-amd64-disk1.img"
$gl_image_uri = "http://cloud-images.ubuntu.com/${gl_release}/current/${gl_image_name}"

exec {"/usr/bin/wget ${gl_image_uri}":
  cwd => '/var/www',
  path => ['/bin','/usr/bin'],
  creates => "/var/www/${gl_image_name}"
}
