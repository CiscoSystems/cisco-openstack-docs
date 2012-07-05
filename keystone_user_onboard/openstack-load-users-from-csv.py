#!/usr/bin/python
#
#    Copyright 2012 Cisco Systems, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
import argparse
from email.mime.text import MIMEText
import csv
import ConfigParser
import os
import random
import smtplib
import string
import sys


import keystoneclient.v2_0.client
DESCRIPTION = """Creates OpenStack users and tenants based on a CSV file.

If run on the same host as Keystone, the admin token will automatically
be grabbed from /etc/keystone/keystone.conf (if you have access to this
file).

If run on a different host, you can pass credentials for Keystone by
setting and exporting the SERVICE_TOKEN and SERVICE_ENDPOINT environment
variables or by setting and exporting the OS_TENANT_NAME, OS_USERNAME,
OS_PASSWORD, and OS_AUTH_URL environment variables.

The CSV file format is as follows:
firstname,lastname,username,email

Fields are separated by comma. Use double quotes (") to quote values
that contain a comma."""
NO_CREDS_FOUND = "No credentials for Keystone provided and none could be found"
KEYSTONE_CONFIG = '/etc/keystone/keystone.conf'


def check_env_for_keystone_creds(env=os.environ):
    if 'SERVICE_TOKEN' in env and 'SERVICE_ENDPOINT' in env:
        return True
    if ('OS_TENANT_NAME' in env and
        'OS_USERNAME' in env and
        'OS_PASSWORD' in env and
        'OS_AUTH_URL' in env):
        return {'username': env['OS_USERNAME'],
                'tenant_name': env['OS_TENANT_NAME'],
                'password': env['OS_PASSWORD'],
                'auth_url': env['OS_AUTH_URL']}
    if ('SERVICE_TOKEN' in env and
        'SERVICE_ENDPOINT' in env):
        return {'endpoint': env['SERVICE_ENDPOINT'],
                'token': env['SERVICE_TOKEN']}
    if os.path.exists(KEYSTONE_CONFIG):
        config = ConfigParser.SafeConfigParser()
        config.read(KEYSTONE_CONFIG)

        # ConfigParser won't let you look things up directly in the
        # DEFAULT section. Instead we choose a random section and
        # rely on the DEFAULT section feeding defaults into that.
        some_section = config.sections()[0]
        if config.has_option(some_section, 'admin_token'):
            return {'endpoint': 'http://localhost:35357/v2.0/',
                    'token': config.get(some_section, 'admin_token')}
    return False


def generate_password(length):
    chars = string.letters + string.digits
    return ''.join([random.choice(chars) for x in range(length)])


def get_role_by_name(client, name):
    for role in client.roles.list():
        if role.name == name:
            return role
    return None

users = {}
tenants = {}


def pull_users_from_keystone(client):
    global users
    for user in client.users.list():
        users[user.name] = user


def pull_tenants_from_keystone(client):
    global tenants
    for tenant in client.tenants.list():
        tenants[tenant.name] = tenant


def main(argv=sys.argv[1:]):
    global users
    global tenants
    raw_formatter = argparse.RawDescriptionHelpFormatter
    argparser = argparse.ArgumentParser(description=DESCRIPTION,
                                        formatter_class=raw_formatter)
    argparser.add_argument('horizon_url', help="Base URL for Horizon")
    argparser.add_argument('support_address',
                           help="E-mail address for support")
    argparser.add_argument('csv_file', help="Name of the CSV file")
    argparser.add_argument('mail_template', help="Name of the e-mail template")
    argparser.add_argument('--role', default="Member",
                           help="role to assign to users [default: Member]")
    argparser.add_argument('--smtp_host', default="localhost",
                           help="SMTP host [default: localhost]")
    argparser.add_argument('--common_tenant', metavar="TENANT", default=None,
                           help="If set, all users will be added to TENANT. "
                                "The default is to create a tenant per user.")
    args = argparser.parse_args(argv)

    creds = check_env_for_keystone_creds()

    if not creds:
        argparser.error(NO_CREDS_FOUND)

    client = keystoneclient.v2_0.client.Client(**creds)
    try:
        client.tenants.list()
    except keystoneclient.exceptions.AuthorizationFailure:
        argparser.error("Failed to autenticate with Keystone")

    role = get_role_by_name(client, args.role)
    if not role:
        role = client.roles.create(args.role)

    pull_users_from_keystone(client)
    pull_tenants_from_keystone(client)

    data = csv.reader(open(args.csv_file, 'rb'), delimiter=',', quotechar='"')
    for first_name, last_name, user_name, email in data:
        if args.common_tenant:
            tenant_name = args.common_tenant
            tenant_description = 'Shared Tenant'
        else:
            tenant_name = user_name
            tenant_description = "%s %s" % (first_name, last_name)

        if tenant_name in tenants:
            tenant = tenants[user_name]
            if not args.common_tenant:
                print("Tenant named %s already exists. "
                      "Not creating." % user_name)
        else:
            tenant = client.tenants.create(tenant_name,
                                           description=tenant_description)
            tenants[tenant_name] = tenant

        password = generate_password(8)

        if user_name in users:
            user = users[user_name]
            print("User named %s already exists. "
                  "Only updating password." % user_name)
            client.users.update_password(user, password)
        else:
            user = client.users.create(name=user_name,
                                       password=password,
                                       email=email,
                                       tenant_id=tenant.id)

        roles = user.list_roles(tenant)
        if role in roles:
            print("User %s already has the %s role on tenant %s. "
                 "Not adding." % (user_name, args.role, user_name))
        else:
            tenant.add_user(user, role)

        with open(args.mail_template, 'r') as fp:
            mail = fp.read()
        mail = mail.replace('%FIRST_NAME%', first_name)
        mail = mail.replace('%LAST_NAME%', last_name)
        mail = mail.replace('%USER_NAME%', user_name)
        mail = mail.replace('%EMAIL%', email)
        mail = mail.replace('%PASSWORD%', password)
        mail = mail.replace('%HORIZON_FQDN%', args.horizon_url)
        mail = mail.replace('%SUPPORT_ADDRESS%', args.support_address)

        msg = MIMEText(mail)
        msg['Subject'] = 'Welcome to OpenStack'
        msg['From'] = args.support_address
        msg['To'] = email
        msg.as_string()
        s = smtplib.SMTP(args.smtp_host)
        s.sendmail(args.support_address, [email], msg.as_string())
        s.quit()

if __name__ == '__main__':
    sys.exit(not main())
