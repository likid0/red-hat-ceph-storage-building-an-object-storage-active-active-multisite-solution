# Getting Familiar with our Lab environment

Our Lab environment is composed of two Datacenters, DC1 and DC2,  with one Red hat Ceph Storage Cluster(RHCS) on each site.

Once you access your Lab Environment you will be on the bastion host, this node has access to both DCs, from the Bastion host you have access to all servers via ssh with the cloud-user user, so for example to connect to cepha you can use:

`bastion# ssh cloud-user@cepha
 cepha$ sudo -i`

Here is a Diagram of the Lab environment

<img src="labIntro4/images/lab_description.jpg" width="120" height="120"/>


## Network details for DC1 datacenter RHCS deployment

### DC1 has 2 networks:

| Network Name     | CIDR     |
| :------------- | :------------- |
| Ceph Public Network       |    10.0.0.0/24    |
| Ceph Private Network      |    192.168.0.0/24 |

### DC1 has the following VMs:


* 1 HA proxy node:

| Hostname     | IP     |
| :------------- | :------------- |
| lbdc1.summit.lab       |  10.0.0.100      |


* 3 ceph nodes:

| Hostname     | IP     |
| :------------- | :------------- |
| cepha.summit.lab       |  10.0.0.11     |
| cephb.summit.lab       |  10.0.0.12     |
| cephc.summit.lab       |  10.0.0.13     |  


* 1 Ceph Metrics node:

| Hostname     | IP     |
| :------------- | :------------- |
| metricsd.summit.lab       |  10.0.0.14     |


## Network details for DC2 datacenter RHCS deployment

### DC2 has 2 networks:

| Network Name     | CIDR     |
| :------------- | :------------- |
| Ceph Public Network       |    172.16.0.0/24    |
| Ceph Private Network      |    192.168.1.0/24 |

### DC2 has the following VMs:

* 1 HA proxy node:

| Hostname     | IP     |
| :------------- | :------------- |
| lbdc1.summit.lab       |  172.16.0.100      |


* 3 ceph nodes:

| Hostname     | IP     |
| :------------- | :------------- |
| ceph1.summit.lab       |  172.16.0.11     |
| ceph2.summit.lab       |  172.16.0.12     |
| ceph3.summit.lab       |  172.16.0.13     |  


* 1 Ceph Metrics node:

| Hostname     | IP     |
| :------------- | :------------- |
| metrics4.summit.lab       |  172.16.0.14     |


Each RHCS cluster consists of 3 VMs, each VM will run:

* 1 x Ceph Monitor Service
* 1 x Ceph MGR service
* 2 x Ceph OSD Services
* 1 x CEPH RGW Service


## Lab exercises

To save some time the RHCS ceph cluster and Ceph-Netrics is already deployed for you in DC1.

The bastion host is configured as a ceph client so you can check the status of the RHCS ceph cluster installed in dc1 using:

`ceph --cluster dc1 -s`

First we will deploy the second (DC2) RHCS Ceph cluster, configure the RGWs services there.

In second place we will configure RGW multi-site replication, where objects can be uploaded to both sites and then replicated to the other cluster

Once we have the RGW mulsi-tiste configured we will use a S3 client to test our deployment.

Finally we will deploy Ceph-Metrics on DC2, so we can check how our cluster is performing while we are uploading objects with the S3 client.

## [**Next: Install and configure RHCS ceph cluster in DC2 site**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/scenario1/01-DC2_ceph_cluster_installation)

## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
