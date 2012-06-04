General UCS C-series Reference Model
====================================

The following items are the key components of a UCS C-series reference system.  They can be mixed/matched as appropriate for a particular targeted solution.

In general, although the automated deployment solutions do not current drive a highly available management and systems infrastructure, the components are listed in appropriate quantities to support enterprise class availablility of the management and infrastructure components.

Physical Compute
----------------

There are three models for compute systems in the reference architecture:  Control, Compute, and Storage.

### Control Nodes

Control nodes support the control and systems infrastructure management functions of the system.  In the current automated deployment paradigm, one of the control nodes is used as a build server, with the other node acting as the openstack management system/domain.  These nodes can also act in a standalone and/or paired fashion to support a separate database, AMQP, and/or Swift proxy function as necessary.  Currently we are modeling the deployment as a pair of control nodes that provide the following functions:

* Horizon and Nagios dashboards
* Nova compute API
* Nova network API
* Glance image management API
* Keystone authentication engine
* A memcached/mysql database to back the control services

In the future, swift-proxy functions, and possibly a virtualized HA management function (HA proxy and/or Cisco virtual ACE appliance) will also be deployed on the control infrastrucutre.

The current model for these systems as follows:

* UCS C-220-M3 platform (UCSC-C220-M3S)
* 2x Intel E5-2609 CPUs at 2.4GHz (UCS-CPU-E5-2609)
* 4x 8GB DDR3-1333 MHz 1.35V memory  (UCS-MR-1X0824X-A)
* 2x 300GB 10K SAS HDD in RAID 1 configuration (A03-D300GA2)
* LSI 2008 SAS mezzanine RAID controller (UCSC-RAID-11-C220)
* Cisco P81E dual 10Gb Datacenter Ethernet VIC (N2XX-ACPCI01)
* 2x 650W power supply (UCSC-PSU-650W)

### Compute Nodes

The compute nodes support 
