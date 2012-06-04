Editing your cobbler-node.pp
============================

There are three principal sections:  

* The class {cobbler: }
	This sets up cobbler
* The cobbler::ubuntu::preseed definition(s)
	This defines specific parameters needed to preseed a particular server type
* The cobbler::node definition(s)
	This defines a specific node setup in cobbler (allows PXE to work properly)

Note, all of these definitions and classes sit inside a puppet node definition. This can either be a name that maps to your cobbler "build" node, or it can be 'inherits cobbler-node' to the more specific node (remember though, only one inherits per node definition)

So, your cobbler-node.pp file should look something like:

	node cobbler-node {
		class {cobbler:
			blah,blah,blah,
		}
	
		cobbler::ubuntu::preseed {'my-preseed':
			blah,blah,blah,
		}
	
		cobbler::ubuntu::preseed {'my-other-preseed:
			blub,blub,blub,
		}
	
		cobbler::node {'node-1':
			blah,blah,blah,
		}
	
		cobbler::node {'node-2':
			blue,blue,blue,
		}
	}


class {cobbler: }
-----------------

This contains all of the information needed to get cobbler running. You will need to decide if you are going to let cobbler manage a local DNS and DHCP instance, or if you want to configure those outside of cobbler.  We'll assume that you're going to hand the keys over to cobbler, and this puppet environment is tuned for that (the rest is classically left as an exercise for the reader).

For this, you will be pointing all of your configured nodes back to the cobbler server for DNS, DHCP, and likely apt-cache services. If you add NTP to your cobbler server, you can point NTP back to here as well (NTP must be in sync against the puppetmaster at a minimum, and we currently deploy both cobbler and puppetmaster on the same node, so this is a _good_ idea.)

So, you'll really only need ip-address-info: cobbler_ip, network_netmask, network_ip_gateway, external_DNS (if you want anything else resolved beyond what you define via your cobbler host definitions).  That sould get you there. If you follow the simple puppet scripts, apt-cacher-ng and ntp will both be installed on the cobbler host, so you can safely point the NTP service and proxy back to the same IP Address (leave the 3142 port alone on the cache, that's where apt-cacher-ng runs).

Note the IP address range, the node definitions by default assume they'll be able to reach this address range, or more likely be a part of it.

cobbler::ubuntu::preseed
------------------------

Other than the fun of writing pre-seed late-command sections for fun and profit (or more likley for adding specific tools or components needed for the rest of your enviornment that for some reason can't be puppet managed), you will most likley only have to create your own preseed definitions if your disk layout differs from one of the pre-defined ones in the example environment. So far, it seems that the  model is as follows:

* if you do not have a RAID controller (ucs blades all seem to have one, c-series can be ordered without):
	* your boot disk will be /dev/sda
	* additional disks will /dev/sdb,/dev/sdc, etc...
* if you do have a RAID controller (MegaRAID or mezanine LSI-SAS)
	* your boot disk will be /dev/sdc
	* additional disks will be /dev/sdd,/dev/sde, etc...

Note that the LSI-SAS controller can be configured as a passthrough, exposing the individual devices as though there was no RAID controller, but the devices will still start with /dev/sdc.  It doesn't seem to be possible to do this with the Mega-RAID controller.

Whatever name you choose, you will need to reference in the cobbler::node defintion associated with that device, so make them descriptive, but not too long.


cobbler::node definitions
-------------------------

An example would be (in YAML for future autoingestion into puppet):

	sdu-os-1:
		domain-name:  sdu.lab
		ip-address: 192.168.100.101
		mac-address: 00:25:5B:00:01:01
		power-address: 192.168.26.15:org-SDU
		power-user: admin
		power-password: Cisco!12345
		power-id: SDU-OS-1
		power-type: ucs
		preseed: c200-nomez-4disk
		additional-hosts: ['nova','keystone','glance','swift-proxy']

Going through the list above:

* sdu-os-1:  This is the node name, and what will principally be used in "cobbler system --name=node_name" CLI commands.
* domain-name: this is used principally by puppet to append to the node-name (puppet works principally off of FQDN)
* mac-address: this is the MAC address of a PXE capable interface that has to reside in the same network as the cobbler server (mangement and or Public today)
* ip-address:  Currently we're using pre-defined static addresses.  This should come out of your "public" or "management" network space. This should be in the same ranged defined in the "class {cobbler:}" section.
* power-*: Two power types have been tested against UCS:  "ucs" for UCSM nodes, and "ipmitool" for Rack servers.  For ucs nods, power-address can include an optional sub-organization (as in the example above) appeneded after a : to the UCSM management IP address, or just be the address of the UCSM IP if the names are in the root organization.  UCSM power-id is the service profile name.  For rack servers: ipmitool is the current method, user/password/address are the CIMC address and power-id isn't used.
* preseed: see the previous section. This is the specific preseed you set up for this node type.
* additional-hosts: if the node is going to run addiitonal services, it's often good to include their names in DNS, and if you let cobbler run DNS and DHCP for the cloud, these names will get added to the host entry.

Using this file
---------------

So long as you include

	import cobbler-node.pp

In your site.pp file, and copy your cobbler-node.pp file to your manifests directory, and either name the encapsulating node definition to something that matches some section of your build/cobbler/puppetmaster server, or inherit it, e.g.:

	node \cobbler-puppet.sdu.lab\ inherits cobbler-node {
		
	}
	
You can then apply this:

	puppet apply --verbose site.pp
	
And your cobbler enviornemnt should be ready.

Helper script for "resetting" or deploying your nodes
-----------------------------------------------------

So you're all ready to go... Now what?

How about:

	cobbler system poweron --name='node-1'
	
That'll work.  But you can also use the helper script "clean_nodes.sh" that's in the examples directory.

	./clean_nodes.sh node-1 domain.name

(You can also edit the file, and pre-define the domain-name to simplify the CLI)