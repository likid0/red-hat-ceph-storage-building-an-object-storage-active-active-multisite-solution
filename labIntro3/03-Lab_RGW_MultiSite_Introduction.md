# Ceph Rados Gateway Multisite Introduction

We have seen how Ceph implements Object Storage APIs using RGWs components.
Now, we can see the different set-ups that can be made using RGWs.

To understand them, first we need to understand some key concepts:
 Following are the basic terminologies that would be used:

* **Zone**: A zone is logical grouping of one or more Ceph Object Gateway instances. There will be one Zone that should be designated as the master zone in a zonegroup, which will handle all bucket and user creation.

* **Zonegroup**: A zonegroup consists of multiple zones, this approximately corresponds to what used to be called as a region in pre Jewel releases for federated deployments. There should be a master zonegroup that will handle changes to the system configuration.

* **Zonegroup map**: A zonegroup map is a configuration structure that holds the map of the entire system, ie. which zonegroup is the master, relationships between different zonegroups and certain configurables like storage policies.

* **Realm**: A realm is a container for zonegroups, this allows for separation of zonegroups themselves between clusters. It is possible to create multiple realms, making it easier to run completely different configurations in the same cluster.

* **Period**: A period holds the configuration structure for the current state of the realm. Every period contains a unique id and an epoch. A period’s epoch is incremented on every commit operation. Every realm has an associated current period, holding the current state of configuration of the zonegroups and storage policies. Any configuration change for a non master zone will increment the period’s epoch. 
Changing the master zone to a different zone will trigger the following changes: - A new period is generated with a new period id and epoch of 1 - Realm’s current period is updated to point to the newly generated period id - Realm’s epoch is incremented



## Resources

* [RGWs Multi Site docs](http://docs.ceph.com/docs/master/radosgw/multisite/)

## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)