#!/bin/bash
domain="sdu.lab"
sudo cobbler system edit --name=$1 --netboot-enable=Y
sudo cobbler system poweroff --name=$1
sudo cobbler system poweron --name=$1
sudo puppet cert clean $1.$domain
sudo ssh-keygen -R $1
