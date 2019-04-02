# What is Ceph?

Red Hat Ceph Storage is a distributed data object store designed to provide excellent performance, reliability and scalability. Distributed object stores are the future of storage, because they accommodate unstructured data, and because clients can use modern object interfaces and legacy interfaces simultaneously. 

For example:

* APIs in many languages (C/C++, Java, Python)
* RESTful interfaces (S3/Swift)
* Block device interface
* Filesystem interface

<center><img src="labIntro1/images/ceph-components.png" style="width:600px;" border=0/></center>

The power of Red Hat Ceph Storage can transform your organization’s IT infrastructure and your ability to manage vast amounts of data, especially for cloud computing platforms like RHEL OSP. Red Hat Ceph Storage delivers extraordinary scalability–thousands of clients accessing petabytes to exabytes of data and beyond.

At the heart of every Ceph deployment is the 'Ceph Storage Cluster.' It consists of three types of daemons:

* **Ceph OSD Daemon**: Ceph OSDs store data on behalf of Ceph clients. Additionally, Ceph OSDs utilize the CPU, memory and networking of Ceph nodes to perform data replication, erasure coding, rebalancing, recovery, monitoring and reporting functions.

* **Ceph Monitor**: A Ceph monitor maintains a master copy of the Ceph Storage cluster map with the current state of the storage cluster. Monitors require high consistency, and use Paxos to ensure agreement about the state of the Ceph Storage cluster.

* **Ceph Manager**: New in RHCS 3, a Ceph Manager maintains detailed information about placement groups, process metadata and host metadata in lieu of the Ceph Monitor—​significantly improving performance at scale. The Ceph Manager handles execution of many of the read-only Ceph CLI queries, such as placement group statistics. The Ceph Manager also provides the RESTful monitoring APIs.

Red Hat Ceph Storage is a scalable, open, software-defined storage platform that combines the most stable version of the Ceph storage system with a Ceph management platform, deployment utilities, and support services.

<center><img src="labIntro1/images/ceph-cluster.png" style="width:600px;" border=0/></center>


Additionally, when using Red Hat Ceph Storage for File System or Block Storage, the following nodes would be needed as well:

* **MDS nodes**: (FileSystem storage)
Each Metadata Server (MDS) node runs the MDS daemon (ceph-mds), which manages metadata related to files stored on the Ceph File System (CephFS). The MDS daemon also coordinates access to the shared cluster.

* **Object Gateway node**: (RGW) (Object Storage)
Ceph Object Gateway node runs the Ceph RADOS Gateway daemon (ceph-radosgw), and is an object storage interface built on top of librados to provide applications with a RESTful gateway to Ceph Storage Clusters. The Ceph Object Gateway supports two interfaces: S3 and OpenStack Swift.


## What can Red Hat Ceph Storage do for you?

* **A single, open, and unified platform**
Red Hat Ceph Storage delivers software-defined storage on your choice of industry-standard hardware. With block, object, and file storage combined into 1 platform, including the most recent addition of CephFS, Red Hat Ceph Storage efficiently and automatically manages all your data. It also supports backward compatibility to existing block storage resources using storage networking standards, iSCSI and Network File System (NFS).


* **Performance that scales**
Take advantage of high-performance object storage for emerging applications like video delivery networks, cloud DVR, and network functions virtualization (NFV). Deploy Red Hat Ceph Storage clusters and NVMe SSD in performance tiers that are optimized to support the bandwidth, latency, and IOPS requirements of high-performance workloads.

* **Open software on industry standard hardware**
Lower the cost of storing your data by building a storage cluster using standard, economical servers and disks. Red Hat Ceph Storage isn’t picky about hardware, so select the servers you need based on performance, capacity, or both. Use your own systems, or check out the storage server vendors who have tested and evaluated specific cluster options for different cluster sizes and workload profiles.


* **Interoperability**
Red Hat Ceph Storage is tightly integrated with Red Hat OpenStack® Platform and all its services, including Nova, Cinder, Swift, Glance, and Manila. You can instantly provision hundreds of virtual machines from a single snapshot and build fully supported clouds on standard hardware. You can also use Red Hat Ceph Storage to deliver 1 of the most compatible Amazon Web Services (AWS) S3 object store implementations. Red Hat Ceph Storage is now also certified as a backup endpoint with Veritas NetBackup and Rubrik Cloud Data Management.

## Resources

* [What is Red Hat Ceph Storage?](https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/3/html/installation_guide_for_red_hat_enterprise_linux/what_is_red_hat_ceph_storage)

* [Red Hat Ceph Storage Features](https://www.redhat.com/en/technologies/storage/ceph/features)

* [Upstream Ceph docs](http://docs.ceph.com/docs/master/)


## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)