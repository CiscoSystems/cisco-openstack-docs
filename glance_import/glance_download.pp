$release_download = 'precise'
$image_name = "${release_download}-server-cloudimg-amd64-disk1.img"
$image_uri = "http://cloud-images.ubuntu.com/${release_download}/current/${image_name}"

exec {"/usr/bin/wget ${image_uri}":
  cwd => '/var/www',
  path => ['/bin','/usr/bin'],
  creates => "/var/www/${image_name}"
}
