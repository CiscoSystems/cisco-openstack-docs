keystone user add script
========================

A script to help manage bulk user import.

Thescript expects an input file in csv format wth the following schema:

FirstName,LastName,user-id,email-address

Note, the most critical are the user-id and email-address.

You may also want to edit the script to allow for non-"openstack" tenant deployments.

Enjoy
