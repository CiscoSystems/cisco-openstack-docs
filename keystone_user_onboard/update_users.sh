#!/bin/bash
export SERVICE_TOKEN=admin_token
export SERVICE_ENDPOINT=http://192.168.100.104:35357/v2.0/

keystone=/usr/bin/keystone
SEQ=/usr/bin/seq

tenant=openstack
tenant_id=$($keystone tenant-list | grep $tenant | awk '{print $2}')
role=admin
role_id=$($keystone role-list | grep $role | awk '{print $2}')
for name in $($keystone user-list | grep 'True' | awk '{print $2}')
do
    echo "${keystone} user-role-add --user=${name} --role=${role_id} --tenant_id=$tenant_id"
    $keystone user-role-add --user=${name} --role=${role_id} --tenant_id=$tenant_id
done
