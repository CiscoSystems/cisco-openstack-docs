#!/bin/bash

if [[ $argv -lt 3 ]]
	then
	echo -e "Usage:\n${0} user password e-mail@address [tenant=openstack]"
else
	if [[ $argv -eq 3 ]] 
		then
		keystone user-create --name=${1} --pass=${2} --email=${3}
	else
		keystone user-create --name=${1} --pass=${2} --email=${3} --default_tenant=${4}
	fi
fi