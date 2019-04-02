# Ceph Rados Gateway Multisite Introduction

## RGWs Multisite concepts

We have seen how Ceph implements Object Storage APIs using RGWs components.
Now, we can see the different multisite set-ups that can be made using RGWs.

To understand multisite set-ups, first we need to understand some key multisite concepts: realm, zone, zone-group or period.

* **Realm**: Represents a globally unique namespace consisting of one or more zonegroups. Each zonegroups contains one or more zones and each zone contains buckets, where objects are stored.
Realms also contain the notion of periods. Each period represents the state of the zonegroup and zone configuration in time. 

* **Period**: Every period contains a unique id and an epoch. A period’s epoch is incremented on every commit operation. Every realm has an associated current period, holding the current state of configuration of the zonegroups and storage policies. Each time you make a change to a zonegroup or zone, update the period and commit it. Each cluster map maintain a history of their map versions. Each of these versions is called epoch.

**NOTE**: Using a zonegroup with multiple zones is supported. Using multiple zonegroups is a
technology preview only, and is not supported in production environments.

<center><img src="labIntro3/images/ceph-realm.png" style="width:400px;" border=0/></center>

* **Zone**: Defines a logical group consisting of one or more Ceph Object Gateway instances.Configuring zones differs from typical Ceph configuration procedures, because not all of the settings end up in a Ceph configuration file. There will be one zone that should be designated as the Master zone in a zonegroup
The Master zone will handle all bucket and user creation.Secondary zone can receive bucket and user operations, but will redirect them to the Master zone. If the Master zone is down, bucket and user operations will fail
It is possible to promote a secondary zone to Master zone.

**NOTE**: Promoting a secondary zone is a complex operation. It is recommended only when the Master zone will be down for a long period of time.

* **Zonegroup**: A zonegroup consists of multiple zones, this approximately corresponds to what used to be called as a region in pre Jewel releases for federated deployments. There should be a master zonegroup that will handle changes to the system configuration.

## RGWs Multisite Configurations

A single zone configuration typically consists of one zonegroup containing one zone and one or more ceph-radosgw instances where you may load-balance gateway client requests between the instances. In a single zone configuration, typically multiple gateway instances point to a single Ceph storage cluster.

Multi-site (actually, multi-zone) consists of one zonegroup and multiple zones, each zone with one or more ceph-radosgw instances. Each zone is backed by its own RHCS. It provides disaster recovery and it is a foundation for Content Delivery Networks (CDN). The replication between zones is an asynchronous process

**NOTE**: Other multi-site configurations exists, but are not currently supported by Red Hat: 
* Multi-zonegroup
* Multiple Realms

<center><img src="labIntro3/images/ceph-multisite.png" style="width:400px;" border=0/></center>

## Resources

* [Upstream RGWs Multi Site docs](http://docs.ceph.com/docs/master/radosgw/multisite/)

* [Red Hat Ceph Storage Object Gateway Guide For RHEL](https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/3/html-single/object_gateway_guide_for_red_hat_enterprise_linux/index)

## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)