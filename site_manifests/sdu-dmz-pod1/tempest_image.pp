$release_name = 'precise'
$server_name = 'build-os'
$tempest_image_name = "${release_name}-server-cloudimg-amd64-disk1.img"
$tempest_image_uri = "http://${server_name}/${tempest_image_name}"
$tempest_os_tenant = 'openstack'
$tempest_os_username = 'admin'
$tempest_os_password = 'Cisco123'
$tempest_os_auth_url = 'http://192.168.200.40:5000/v2.0/'

exec {"glance add -I ${tempest_os_username} -K ${tempest_os_password} -T ${tempest_os_tenant} -N ${tempest_os_auth_url} name=tempest-1 is_public=true container_format=bare disk_format=qcow2 copy_from=${tempest_image_uri}":
  unless => "glance index | grep tempest-1 2>/dev/null",
}
exec {"glance add -I ${tempest_os_username} -K ${tempest_os_password} -T ${tempest_os_tenant} -N ${tempest_os_auth_url} name=tempest-2 is_public=true container_format=bare disk_format=qcow2 copy_from=${tempest_image_uri}":
  unless => "glance index | grep tempest-2 2>/dev/null",

}
