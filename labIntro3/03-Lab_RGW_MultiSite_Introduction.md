# Ceph Rados Gateway Multisite Introduction

We have seen how Ceph implements Object Storage APIs using RGWs components.
Now, we can see the different set-ups that can be made using RGWs.

To understand them, first we need to understand some key concepts: realm, zone, zone-group and epoch.

A single zone configuration typically consists of one zone group containing one zone and one or more ceph-radosgw instances where you may load-balance gateway client requests between the instances. In a single zone configuration, typically multiple gateway instances point to a single Ceph storage cluster. However, Red Hat supports several multi-site configuration options for the Ceph Object Gateway:

* **Multi-zone**: A more advanced configuration consists of one zone group and multiple zones, each zone with one or more ceph-radosgw instances. Each zone is backed by its own Ceph Storage Cluster. Multiple zones in a zone group provides disaster recovery for the zone group should one of the zones experience a significant failure. In Red Hat Ceph Storage 2, each zone is active and may receive write operations. In addition to disaster recovery, multiple active zones may also serve as a foundation for content delivery networks. To configure multiple zones without replication, see Section 5.12, “Configuring Multiple Zones without Replication”.

* **Multi-zone-group**: Formerly called 'regions', Ceph Object Gateway can also support multiple zone groups, each zone group with one or more zones. Objects stored to zone groups within the same realm share a global namespace, ensuring unique object IDs across zone groups and zones.

* **Multiple Realms**: In Red Hat Ceph Storage 2, the Ceph Object Gateway supports the notion of realms, which can be a single zone group or multiple zone groups and a globally unique namespace for the realm. Multiple realms provides the ability to support numerous configurations and namespaces.

* **Period**: A period holds the configuration structure for the current state of the realm. Every period contains a unique id and an epoch. A period’s epoch is incremented on every commit operation. Every realm has an associated current period, holding the current state of configuration of the zonegroups and storage policies. Any configuration change for a non master zone will increment the period’s epoch. 
Changing the master zone to a different zone will trigger the following changes: - A new period is generated with a new period id and epoch of 1 - Realm’s current period is updated to point to the newly generated period id - Realm’s epoch is incremented


## Resources

* [Upstream RGWs Multi Site docs](http://docs.ceph.com/docs/master/radosgw/multisite/)

* [Red Hat Ceph Storage Object Gateway Guide For RHEL](https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/3/html-single/object_gateway_guide_for_red_hat_enterprise_linux/index)

## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)