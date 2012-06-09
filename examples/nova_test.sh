#!/bin/bash
#
# assumes that resonable credentials have been stored at
# /root/auth
source /root/openrc

# get an image to test with
#wget http://uec-images.ubuntu.com/releases/11.10/release/ubuntu-11.10-server-cloudimg-amd64-disk1.img
#wget http://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img
wget http://128.107.252.163:/precise-server-cloudimg-amd64-disk1.img

# import that image into glance
glance add name="precise-amd64" is_public=true container_format=ovf disk_format=qcow2 < precise-server-cloudimg-amd64-disk1.img

IMAGE_ID=`glance index | grep 'precise-amd64' | head -1 |  awk -F' ' '{print $1}'`

#wget https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img

#glance add name='cirros image' is_public=true container_format=bare disk_format=qcow2 < cirros-0.3.0-x86_64-disk.img

#IMAGE_ID=`glance index | grep 'cirros image' | head -1 |  awk -F' ' '{print $1}'`

# create a pub key
ssh-keygen -f /tmp/id_rsa -t rsa -N ''
nova keypair-add --pub_key /tmp/id_rsa.pub key_precise

nova secgroup-create precise_test 'Precise test security group'
nova secgroup-add-rule precise_test tcp 22 22 0.0.0.0/0
nova secgroup-add-rule precise_test tcp 80 80 0.0.0.0/0
nova secgroup-add-rule precise_test icmp -1 -1 0.0.0.0/0

floating_ip=`nova floating-ip-create | grep None | awk '{print $2}'`

nova boot --flavor 1 --security_groups precise_test --image ${IMAGE_ID} --key_name key_precise precise_vm

nova show precise_vm

nova add-floating-ip precise_vm $floating_ip
# wait for the server to boot

sleep 60
ssh ubuntu@$floating_ip -i /tmp/id_rsa

