# Getting Familiar with our Lab environment

Our Lab environment is composed by two separated Ceph clusters. One (DC1) is already deployed for you.
Each cluster consists of 3 VMs, each VM will run:
* 1 Ceph Monitor Service
* 2 Ceph OSD Services
* 1 CEPH RGW Service

The idea is that you first we will deploy the second (DC2) Ceph cluster, configure the RGWs there,
then configure an active/active multi-site replication, so objects are replicated across clusters, 
and each Ceph cluster RGWs are working in a active mode.

Finally we will deploy 


## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)