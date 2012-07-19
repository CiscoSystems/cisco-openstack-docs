#!/bin/bash

apt-get update
apt-get dist-upgrade -y
apt-get install openssh-server lvm2 ntp puppet git rake ipmitool python-software-properties -y
git clone https://github.com/CiscoSystems/cisco-openstack-docs ~/os-docs
add-apt-repository -y ppa:cisco-openstack-mirror/cisco
apt-get update
apt-get install puppet-openstack-cisco
cp ~/os-docs/examples/{site.pp,cobbler-node.pp} /etc/puppet/manifests/

