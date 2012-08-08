$release = 'precise'
$image_name = "${release}.img"
$image_uri = "http://build-os/${image_name}"
$os_tenant = 'openstack'
$os_username = 'admin'
$os_password = 'Cisco123'
$os_auth_url = "http://192.168.200.40:5000/v2.0/"

exec {"glance add -T ${os_tenant} -N ${os_auth_url} -K ${os_password} -I ${os_username} name=${release} is_public=true disk_format='qcow2' container_format='bare' copy_from=${image_uri}":
  path => ['/bin','/usr/bin'],
  cwd => '/var/www',
  unless => "glance -T ${os_tenant} -N ${os_auth_url} -K ${os_password} -I ${os_username} index | grep ${release} 2>/dev/null",
#  require => Class["openstack::controller"]
  }
