#!/bin/bash

source /root/openrc

tenant_name=ctocloudlab

keystone	tenant-create --name=$tenant_name
keystone	user-create --name=letucker --pass=Cisco123 --email=letucker@cisco.com	--default_tenant=$tenant_name


