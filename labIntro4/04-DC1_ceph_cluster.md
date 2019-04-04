# Getting Familiar with our Lab environment

Our Lab environment is composed of two Datacenters, DC1 and DC2,  with one Red hat Ceph Storage Cluster(RHCS) on each site.

Once you access your Lab Environment you will be on the bastion host, this node has access to both DCs, from the Bastion host you have access to all servers via ssh with the cloud-user user, so for example to connect to cepha you can use:

`bastion# ssh cloud-user@cepha
 cepha$ sudo -i`

Here is a Diagram of the Lab environment

<center><img src="labIntro4/images/lab_description.jpg" style="height:300px;" style="width:600px;" border=0/></center>


### Network details for DC1 datacenter RHCS deployment

#### DC1 has 2 networks:

| Network Name     | CIDR     |
| :------------- | :------------- |
| Ceph Public Network       |    10.0.0.0/24    |
| Ceph Private Network      |    192.168.0.0/24 |

#### DC1 has the following VMs:


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


### Network details for DC2 datacenter RHCS deployment

#### DC2 has 2 networks:

| Network Name     | CIDR     |
| :------------- | :------------- |
| Ceph Public Network       |    172.16.0.0/24    |
| Ceph Private Network      |    192.168.1.0/24 |

#### DC2 has the following VMs:


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


To save some time the Red hat Ceph Storage Cluster(RHCS) and Ceph-Netrics is already deployed for you in DC1.



The idea is that you first we will deploy the second (DC2) RHCS Ceph cluster, configure the RGWs services there,
then configure RGW active/active multi-site replication, so objects are replicated across clusters,
and both Ceph cluster RGWs are working in a active mode.

Once we have the RGW mulsitiste configured we will use a S3 client to test our deployment

Finally we will deploy ceph-metrics on DC2, so we can check how our cluster if performing while we are uploading objects with our S3 client.


## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
