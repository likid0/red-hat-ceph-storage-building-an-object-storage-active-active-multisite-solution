# Getting Familiar with our Lab environment

Our Lab environment is composed of two Datacenters, DC1 and DC2,  with one Red hat Ceph Storage Cluster on each site.

The Red hat Ceph Storage Cluster (DC1) is already deployed for you.

<center><img src="labIntro4/images/lab_description.jpg" style="width:600px;" border=0/></center>

###DC1 has 2 networks:

| Network Name     | CIDR     |
| :------------- | :------------- |
| Ceph Public Network       |    10.0.0.0/24    |
| Ceph Private Network      |    192.168.0.0/24 |

###DC1 has the following VMs:


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



Each cluster consists of 3 VMs, each VM will run:

* 1 Ceph Monitor Service
* 2 Ceph OSD Services
* 1 CEPH RGW Service

The idea is that you first we will deploy the second (DC2) Ceph cluster, configure the RGWs there,
then configure an active/active multi-site replication, so objects are replicated across clusters,
and each Ceph cluster RGWs are working in a active mode.

Finally we will deploy


## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
