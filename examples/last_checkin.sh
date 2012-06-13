#!/bin/bash
echo "Testing against node named $1"
echo "First, let's see if we've asked for a certificate with puppet:"
while ! (puppet cert list --all | grep ${1})
  do echo -n .
  sleep 15
done
echo "Now let's see when we actually checked in:"
last_checkin=$(ls -l /var/lib/puppet/yaml/node/${1}* | awk '{print $8}')
echo $last_checkin
echo "Now we wait for the system to build, boot, and check in one more time:"
while true
  do if [ $(ls -l /var/lib/puppet/yaml/node/${1}* | awk '{print $8}') != $last_checkin ]
    then break
  fi
  echo -n . 
  sleep 15 
done
echo "$1 just checked in at $(ls -l /var/lib/puppet/yaml/node/${1}* | awk '{print $8}') "
