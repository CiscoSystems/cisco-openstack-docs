# Load tempest and an Ubuntu Precise image.

import "tempest_image"

class { 'tempest':
  identity_host        => 'localhost',
  identity_port        => '35357',
  identity_api_version => 'v2.0',
  # non admin user
  username             => 'user1',
  password             => 'user1_password',
  tenant_name          => 'tenant1',
  # another non-admin user
  alt_username         => 'user2',
  alt_password         => 'user2_password',
  alt_tenant_name      => 'tenant2',
  # image information
  image_id             => $::tempest_image_1,#<%= image_id %>,
  image_id_alt         => $::tempest_image_2,#<%= image_id_alt %>,
  flavor_ref           => 1,
  flavor_ref_alt       => 2,
  # the version of the openstack images api to use
  image_api_version    => '1',
  image_host           => 'localhost',
  image_port           => '9292',

  # this should be the username of a user with administrative privileges
  admin_username       => 'admin',
  admin_password       => 'Cisco123',
  admin_tenant_name    => 'openstack',

  git_protocol         => 'git'
}


