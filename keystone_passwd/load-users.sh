#!/bin/bash
SEQ=/usr/bin/seq
users=( $(cat user_names_emails.csv) )

for i in $($SEQ 0 $((${#users[@]} - 1)))
do
  temp=($( echo ${users[$i]} | tr "," "\n " ))
  temp_passwd=($(/usr/bin/mkpasswd ${temp[0]} ${temp[1]}))
  /usr/bin/keystone user-create --name=${temp[2]} --pass=${temp_passwd} --email=${temp[3]}
done

exit 0
