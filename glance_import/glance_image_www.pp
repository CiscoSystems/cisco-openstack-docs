$release = 'precise'
$image_name = "${release}-server-cloudimg-amd64-disk1.img"
$image_uri = "http://cloud-images.ubuntu.com/${release}/current/${image_name}"
$os_tenant = 'openstack'
$os_username = 'admin'
$os_password = 'Cisco123'
$os_auth_url = 'http://192.168.200.40:5000/v2.0/'

Exec{
  logoutput => true,
  path => ['/bin','/usr/bin'],
  cwd => '/var/www',
  environment => ["OS_TENANT_NAME=${os_tenant}","OS_USERNAME=${os_username}","OS_PASSWORD=${os_password}","OS_AUTH_URL=${os_auth_url}"]
}

exec {"/usr/bin/wget ${image_uri}":
  creates => "/var/www/${image_name}"
}
