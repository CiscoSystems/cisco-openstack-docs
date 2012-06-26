
export SERVICE_TOKEN=admin_token
export SERVICE_ENDPOINT=http://10.16.205.61:35357/v2.0/

keystone=/usr/bin/keystone
SEQ=/usr/bin/seq

tenant=openstack
role=Member
users=( $(cat user_names_emails.csv) )


if [[ ! ($($keystone tenant-list | grep $tenant)) ]]
then
  ($keystone tenant-create --name=$tenant --description="Tenant from user-add script")
fi

if [[ ! ($($keystone role-list | grep $role)) ]]
then
  ($keystone role-create --name=Member)
fi

for i in $($SEQ 0 $((${#users[@]} - 1)))
do
  temp=($( echo ${users[$i]} | tr "," "\n " ))
  temp_passwd=ChangeMe
#  temp_passwd=($(/usr/bin/makepasswd))
  if [[ ! ($($keystone user-list | grep ${temp[2]})) ]]
  then
    echo user: ${temp[2]} pass: $temp_passwd
    tenant_id=$($keystone tenant-list | grep $tenant | awk '{print $2}')
    ($keystone user-create --name=${temp[2]} --pass=${temp_passwd} --email=${temp[3]} --tenant_id=$tenant_id)
  fi

done
