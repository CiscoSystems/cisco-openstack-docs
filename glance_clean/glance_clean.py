#!/usr/bin/env python

# vim: tabstop=4 shiftwidth=4 softtabstop=4
# Copyright 2012 Cisco Systems Inc.
# Author: Arvind Somya (asomya@cisco.com

import argparse
import os
import sys

from glance import client as glance_client

parser = argparse.ArgumentParser(description='Script to clean up orphaned Glance images')
parser.add_argument('-d', '--delete', action="store_true",
                    help='Delete orphaned images automatically')
parser.add_argument('--image_path', type=str, required=True,
                   help='Path to the glance image directory')

parser.add_argument('--host', default='localhost')
parser.add_argument('--port', default=9292)
parser.add_argument('--os_tenant_name', default=os.environ['OS_TENANT_NAME'])
parser.add_argument('--os_username', default=os.environ['OS_USERNAME'])
parser.add_argument('--os_password', default=os.environ['OS_PASSWORD'])
parser.add_argument('--os_auth_url', default=os.environ['OS_AUTH_URL'])
parser.add_argument('--os_auth_strategy', default=os.environ['OS_AUTH_STRATEGY'])
parser.add_argument('--os_auth_token', default=os.environ['SERVICE_TOKEN'])

args = parser.parse_args()

path = args.image_path
files = os.listdir(path)

def get_client(args):
    """
    Returns a new client object to a Glance server
    specified by the --host and --port args
    supplied to the CLI
    """
    return glance_client.get_client(
                host=args.host,
                port=args.port,
                username=args.os_username,
                password=args.os_password,
                tenant=args.os_tenant_name,
                auth_url=args.os_auth_url,
                auth_strategy=args.os_auth_strategy,
                auth_token=args.os_auth_token)

orphaned = []
for file in files:
    # Check glance to see if this image is active
    try:
        image = get_client(args).get_image_meta(file)
        if str(image['status']) != 'active':
            orphaned.append(file)
    except:
        orphaned.append(file)

if len(orphaned) == 0:
    print "No orphaned files found!"
    sys.exit(0)

if args.delete:
    print "Deleting the following orphaned file(s):"
    print ','.join(orphaned)
    for orphan in orphaned:
        os.remove(args.image_path + '/' + orphan)
else:
    print "The following files were found orphaned in Glance:"
    print ', '.join(orphaned)
