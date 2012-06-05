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

* UCS C-220-M3 1 RU compute platform (UCSC-C220-M3S)
* 2x Intel E5-2609 CPUs at 2.4GHz (UCS-CPU-E5-2609)
* 4x 8GB DDR3-1333 MHz 1.35V memory  (UCS-MR-1X0824X-A)
* 2x 300GB 10K SAS 2.5" HDD in RAID 1 configuration (A03-D300GA2)
* LSI 2008 SAS mezzanine RAID controller (UCSC-RAID-11-C220)
* Cisco P81E dual 10Gb Datacenter Ethernet VIC (N2XX-ACPCI01)
* 2x 650W power supply (UCSC-PSU-650W)


### Compute Nodes

The compute nodes support principally virtualized compute operations, possibly the OVS or other network based interfaces, and Nova-Volumes iscsi services. These systems have more avaialble cores, and larger disk space to support this function.

The current model for these systems is as follows:

* UCS C-220-M3 1RU compute platform (UCSC-C220-M3S)
* 2x Intel E5-2650 CPUs at 2.0GHz (UCS-CPU-E5-2650)
* 16x 8GB DDR3-1600 MHz 1.35V memory  (UCS-MR-1X082RY-A)
* 8x 500GB 7.2K SATA 2.5" HDD in RAID 5 configuration (A03-D500GC3)
* LSI 2008 SAS mezzanine RAID controller (UCSC-RAID-11-C220)
* Cisco P81E dual 10Gb Datacenter Ethernet VIC (N2XX-ACPCI01)
* 2x 650W power supply (UCSC-PSU-650W)

### Storage Nodes

The big shift in the storage nodes is in the need for additional local storage.  To that end, these systems focus on the larger 2RU C240 platform, and while the RAID controller is not used in the RAID configuration, it is required to address the full 24 disk capability of the C240 platform. The expectation is that these nodes only perform object storage functions, and are not used for other functions in the reference model.

The current model for these system sis as follows:

* UCS C-240-M3 1 RU compute platform (UCSC-C240-M3S)
* 2x Intel E5-2609 CPUs at 2.4GHz (UCS-CPU-E5-2609)
* 4x 8GB DDR3-1333 MHz 1.35V memory  (UCS-MR-1X0824X-A)
* 24x 1TBB 7.2K SATA 2.5" HDD no RAID configuration (A03-D1TBSATA)
* MegaRAID disk controller (UCSC-RAID-9266)
* Cisco P81E dual 10Gb Datacenter Ethernet VIC (N2XX-ACPCI01)
* 2x 650W power supply (UCSC-PSU-650W)

Network
-------

There are multiple options for network infrastructure, depending on actual target function for services, but in the referece model, we are leveraging the Nexus 5000 series devices in order to allow for the use of Cisco's hypervisor bypass network function along with a Layer 3 access termination model.  The Network default configuration uses only the 10Gb VIC interfaces for primary and private network functions, and leverages the onboard LOM ethernet ports for access to the CIMC interface out-of-band management of the C-Series servers while reducing overall network devices deployed into the environment, and still allowing for redundancy in OOBM functions.

Each host will have four switch connections, 2 from the 10GbE VIC via CX-1 copper as the principal network access interfaces, and 2 from the LOM 1GbE copper interfaces for OOBM.  The two switches at ToR (or mid rack for better cable management) will also have 4 total 10GbE connections between them for ISL traffic, vPC peer-link, and heartbeat traffic.

The network platform is made up of two of the following:

* Nexus 5548-UP chassis (N5K-C5548UP-FA)
* Nexux front to back airflow fan module (N5548-FAN)
* Nexus 5548 L3 Daughter Card version 2 (N55-D160L3-V2)
* 1000Base-T SFP for each attached server OOBM (GLC-T)
* 10Gb-CU SFP+ 1m cable (SFP-H10GB-CU1M) for each server, and additional ISL links (2 per switch)
* 10Gbase-SR SFP+ interface for uplink to the rest of the system infrastructure (2 per switch)

