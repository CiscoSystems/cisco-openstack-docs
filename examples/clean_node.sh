#!/bin/bash
if [[ -n $2 ]]
  then domain=$2
  else domain="sdu.lab"
fi
sudo cobbler system edit --name=$1 --netboot-enable=Y
sudo cobbler system poweroff --name=$1
sudo cobbler system poweron --name=$1
sudo puppet cert clean $1.$domain
sudo ssh-keygen -R $1
sudo ssh-keygen -R `host $1 | awk '{print \$4}'`
