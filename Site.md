Modifying the site.pp file
==========================

This file is currently the core of the openstack deployment model with puppet.  In addition to the day 0 Cobbler operations (see the Cobbler-Node.md file for a description of this subset), the site.pp file actually establishes the openstack systems control, compute, storage, and in the future assurance and network infrastructure.

You will want to:

1. Change the node /build-0/ name to match whatever you are going to call your build/cobbler/puppet server in DNS (it's likely the node you're working on, so make it match that).  Note that in node definitions, the names between // are perl regex class expressions and match against the nodes FQDN. So, change:
	* node name (potentially)
	* ntp server addresses (if these aren't appropriate for you)
	* puppet mysql_password

2. Change any passwords or parameters in the node base section:
	* don't tweak the sql_connection parameter, that likely needs to be moved elsewhere
	* Do change the passwords (note: admin_password is the password used in the default openrc file and as the password for the horizon UI 'admin' user as well)
	* admin_email if you want to receive email alerts from the system
	* puppetmaster_address this really should be DNS accessible name, and using an additional host name here should work if you set up your cobbler and puppet servers together.
	* ntp again, same as above, this likely needs a higher order "default" variable.
	* you might want to copy the nova_test.sh file from the examples directory into /etc/puppet/modules/puppet/files after you set have pulled in the prerequisite modules.

3. Update IP addresses in node flat_dhcp.
	* unless you are really segregating your traffic into management/public/and private, you will likley want controller_node_internal and controller_node_public to be the same, and to map to the public address on the node(s) that become your control node (defined in the next section)
	* no need to tweak anything else here.

4. Update node /controller-name/
	* You likely only have to tweak the floating_range, which should map to a subset of addresses in your public range, or map to a specific range that your controller has access to (again, special circumstances apply)
	* make sure the "controller-name" maps to your control node DNS FQDN or some subsection of that

5. node /compute/
	* really you shoudl either replicate this for each node (if you have fun names, like mountain-ranges for your node names), or include a matching regex to capture only your compute nodes for this environment.

That should do it. You should now be able to run:

  puppet apply --verbose site.pp

(You did copy your cobbler-node.pp and site.pp files into the /etc/puppet/manifests directory right?)

Cobbler should be ready to build your machines, and when they start, puppet should pick up and build your openstack environment.  This seems to take ~20 minutes in my environment, and you can watch the /var/log/syslog file on the cobbler/puppetmaster node to see when thigns are done, as in:

	sudo tail -f /var/log/syslog

Once things are running, you will still need to load an image (via the CLI on the control node most likley), and then you can manage most of the system from the web-ui (http://$controller_node_public use the admin user and the password you defined in the site.pp for admin_password).
