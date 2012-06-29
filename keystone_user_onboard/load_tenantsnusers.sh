
export SERVICE_TOKEN=admin_token
export SERVICE_ENDPOINT=http://10.16.205.61:35357/v2.0/

HORIZON_FQDN='http://192.168.100.104'
SUPPORT_ADDRESS='support@opentack.cisco.com http://support.ctocl.cisco.com'
keystone=/usr/bin/keystone
SEQ=/usr/bin/seq

role=Member
opusers=( $(cat user_names_emails.csv) )
temp_passwd=ChangeMe

for i in $($SEQ 0 $((${#opusers[@]} - 1)))
do
temp=($( echo ${opusers[$i]} | tr "," "\n " ))
if [[ ! ($($keystone tenant-list | grep ${temp[2]})) ]]
then
   ($keystone tenant-create --name=${temp[2]} --description="Tenant from user-add script")
fi

if [[ ! ($($keystone role-list | grep $role)) ]]
then
  ($keystone role-create --name=Member)
fi

if [[ ! ($($keystone user-list | grep ${temp[2]})) ]]
  then
echo user: ${temp[2]} pass: $temp_passwd
    tenant_id=$($keystone tenant-list | grep ${temp[2]} | awk '{print $2}')
    ($keystone user-create --name=${temp[2]} --pass=${temp_passwd} --email=${temp[3]} --tenant_id=$tenant_id)
  fi

done


# Email users an introduction mail
telnet outbound.cisco.com 25 <<EOM
helo openstack.sdu.lab
mail from: support@openstack.sdu.lab
rcpt to: ${temp[3]}
Subject: Welcome to OpenStack!

SAVE THIS DOCUMENT!!!!
Hi ${temp[0]},
 
Welcome to your new OpenStack account and the amazing world of cloud.
 
In order to use your shinny new environment, you can either manage your environment via the slick web based user interface available here:
 
http://${HORIZON_FQDN} credentials are:
 
Username: ${temp[2]}
Password: ${temp_passwd}
 
We support both OpenStack and EC2 api calls, along with Swift and S3 storage APIs
 
Openstack credentials are available here: http://${HORIZON_FQDN}/settings/project/
EC2 credentials are available here: http://${HORIZON_FQDN}/settings/ec2/
 
Additional information is available here:  http://${HORIZON_FQDN}/instructions/
 
User password changes are not currently available, so please keep your current user access credentials secure!
 
Thanks,
Your friendly neighborhood OpenStack support team!
${SUPPORT_ADDRESS}
.
EOM

done
