Simple Openstack
================

1) Build an Ubuntu 12.04 system.

You can use the preseed file to build the base os.  Start with the ISO boot (or USB boot), and at the initial installer screen, after you pick your language, hit F6 (or FN-F6 on a mac), and ESC, and add:

 priority=critical locale=en_US url=http://128.107.252.163/preseed

You may need to add network information (unless you have DHCP enabled, which you may want to disable and give control over to cobbler).

Once the node is built log in (localadmin:ubuntu are the default)

  git clone https://github.com/CiscoSystems/cisco-openstack-docs os-docs
  cd os-docs/examples
  rake modules:clone

Then you need to set up your site:

  cp os-docs/examples/site.pp /etc/puppet/manifests/
  cp os-docs/examples/cobbler-node.pp /etc/puppet/manifests/

YOU MUST THEN EDIT THESE FILES.  They are fairly well documented, but please comment with questions.

The puppet it:

  puppet apply -v /etc/puppet/manifests/site.pp

At this point you should be able to load up your cobbled nodes:

  os-docs/examples/clean_node.sh {node_name}



