#!/bin/bash
kernel_id=$(glance add disk_format=aki container_format=aki name=$1-aki < *virtual | grep ID | awk '{print $6}')
ramdisk_id=$(glance add disk_format=ari container_format=ari name=$1-ari < *loader | grep ID | awk '{print $6}')
glance add disk_format=ami container_format=ami name=$1-ami kernel_id=$kernel_id ramdisk_id=$ramdisk_id < *.img
