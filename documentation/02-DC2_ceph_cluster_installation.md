
## CONFIGURE DC2 CEPH CLUSTER #
***
On our bastion host we have ceph-ansible installed for us, because we are managing both of our ceph clusters from one bastion host, we have one ceph-ansible dir per ceph cluster:

```
[root@bastion ~]# ls -l /root/dc*
/root/dc1:
total 4
drwxr-xr-x. 7 root root 4096 Mar 19 11:35 ceph-ansible

/root/dc2:
total 0
drwxr-xr-x. 7 root root 272 Mar 19 11:35 ceph-ansible
```




We have our dc1 ceph cluster running now we are going to deploy our second cluster, to accomplish this we have to follow the following steps:

Go into our ceph-ansible configuration dir:
```

[root@bastion ceph-ansible]# pwd
/root/dc2/ceph-ansible
```

We have a pre-defined inventory, with our ceph nodes for our cluster in dc2.

Like we have mentioned before we are going to run the mons, mgrs, osds on the 3 ceph nodes ceph1,2,3.
We are also adding our ceph nodes and the bastion host as clients so the ceph-keys get copied to the nodes and we can run ceph commands from the bastion.
Finally we will configure our rados gateway to run on ceph1

```

[root@bastion ~]# cat /root/dc2/ceph-ansible/inventory
[mons]
ceph[1:3]

[mgrs]
ceph[1:3]

[osds]
ceph[1:3]

[clients]
ceph[1:3]
0bastion
metrics4

[ceph-grafana]
metrics4

[rgws]
ceph1
.....
```


Run the following command to test the inventory and that ansible connects ok to all nodes. All nodes in the inventory should respond to the ansible ping module and there should be no errors.

```
[root@bastion ceph-ansible]# ansible -i inventory -m ping all
 [WARNING]: Found both group and host with same name: 0bastion

bastion | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
ceph1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
.....
ceph3 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```




To configure our cluster using ceph-ansible we work with the variable files in group_vars, These are the files that we have to take in account to configure our dc2 ceph cluster for this lab:

```
[root@bastion ceph-ansible]# ls -l group_vars/ | grep -v sample
total 136
-rw-r--r--. 1 root root  1724 Mar 18 07:19 all.yml
-rw-r--r--. 1 root root  1927 Mar 18 06:38 clients.yml
-rw-r--r--. 1 root root  1558 Mar 18 06:30 mgrs.yml
-rw-r--r--. 1 root root   257 Mar 18 07:19 osds.yml
-rw-r--r--. 1 root root   929 Mar 18 06:55 rgws.yml
```


There are 2 yml files that we have to modify, so we can configure our dc2 cluster as needed:

- osds.yml
- all.yml

>**NOTE**:   Be careful with indentation and only modify the parameters mentioned.  Syntax errors may lead to cluster misconfiguration which could damage the cluster.

First we are going to configure the OSDs. we need to edit the file and do the following modifications, specify lvm as the osd_scenario, there are several scenarios available non-colocated, colocated and lvm, in our case we are going to use lvm:

```

[root@bastion ceph-ansible]# cat group_vars/osds.yml | grep osd_scenario
#valid_osd_scenarios:
osd_scenario: lvm
```


We have the option to create several osds per disk, we are going to configure 1 osd per disk:
```
[root@bastion ceph-ansible]# cat group_vars/osds.yml  | grep osds
osds_per_device: 1
```

Finally we have to specify the devices on out ceph nodes that we want to configure as osds.

We are going to connect to one of our ceph nodes, and check the disks we have available, we should have 2 10GB disks to configure for our OSDS:
```
[root@bastion group_vars]# ssh  cloud-user@ceph1 "lsblk | grep 10G"
vdc                   253:32   0   10G  0 disk
vdd                   253:48   0   10G  0 disk
```
One we now that we have vdc and vdd , we add them your our osds.yml file:
```
[root@bastion group_vars]# cat osds.yml | tail -3
devices:
  - /dev/vdc
  - /dev/vdd
```
Now we can move on to the next vars file that is all.yml, this is the main config file for the cluster, we need to edit the file and make the following modifications.


Change the cluster name, we are going to name are second cluster dc2:

```
[root@bastion group_vars]# cat /root/dc2/ceph-ansible/group_vars/all.yml | grep "cluster:"
cluster: dc2
```
We are going to configure bluestore as our objecstore:
```
[root@bastion group_vars]# cat all.yml | grep -i osd_objectstore
osd_objectstore: bluestore
```
We are going to define the monitor_interface variable to our publick network eth0:
```
[root@bastion group_vars]# cat all.yml | grep  monitor_interface
monitor_interface: eth0
```
Add the public and cluster networks for dc2, if you check in the network schema for our lab we can see that the public network is 172.16.0.0/24 and the private network where ceph replication will happen is 192.168.1.0/24
```
[root@bastion ~]# cat /root/dc2/ceph-ansible/group_vars/all.yml | grep network
#Ceph Cluster network config###
public_network:  172.16.0.0/24
cluster_network: 192.168.1.0/24
```
For the containerized configuration we will use cephs 3 image rhceph-3-rhel7, and we have to configure the register from where we want to download the container image, the registry for dc2 has the IP 172.16.0.10:
```
###Containerized Configuration###
containerized_deployment: true
ceph_docker_image: "rhceph/rhceph-3-rhel7"
ceph_docker_image_tag: "latest"
ceph_docker_registry: "172.16.0.10:5000"
docker_pull_retry: 6
docker_pull_timeout: "600s"
```

Finally, we have to configure on what interface we want to have the rados gateway listening, we configure our public network interface.

```
[root@bastion ~]# cat /root/dc2/ceph-ansible/group_vars/all.yml | grep radosgw_interface
radosgw_interface: eth0
```

With the rest of the files, just to point out some config options

For the ceph mgr daemon, we add the prometheus manager plugin, this is needed to get ceph-metrics working:
```
root@bastion group_vars]# cat mgrs.yml | grep -i ceph_mgr_modules
ceph_mgr_modules: [status,dashboard,prometheus]
```
For the client with copy_admin_key we copy the admin key to the nodes that are included in the clients group of our inventory
```
[root@bastion group_vars]# cat clients.yml | grep admin_key
copy_admin_key: true
```

With all the variables ready we can start the deployment of the ceph cluster, on the root of the ceph-ansible dir /root/dc2/ceph-ansible we need to run the site-docker.yml playbook
```
[root@bastion ceph-ansible]# cd /root/dc2/ceph-ansible
[root@bastion ceph-ansible]# cp site-docker.yml.sample site-docker.yml
[root@bastion ceph-ansible]# ansible-playbook -i inventory site-docker.yml
```
The installation will take aproximatly 10 minutes, if the installation has finished successfully you will see the ansible summary with 0 errors:
```
PLAY RECAP ************************************************************************************************************************************************************************************************************************************
0bastion                   : ok=67   changed=5    unreachable=0    failed=0   
ceph1                      : ok=508  changed=47   unreachable=0    failed=0   
ceph2                      : ok=319  changed=34   unreachable=0    failed=0   
ceph3                      : ok=321  changed=35   unreachable=0    failed=0   
metrics4                   : ok=67   changed=6    unreachable=0    failed=0   
```

With our DC2 cluster installed lets check the status of both of our clusters and briefly overview there configuration.

Becasue we configured the bastion host as a client we should have the ceph admin keys available in /etc/ceph:
```
[root@bastion ~]# ls -l /etc/ceph/
total 20
-rw-------. 1 ceph ceph 159 Mar 19 11:49 dc1.client.admin.keyring
-rw-r--r--. 1 root root 624 Mar 19 11:49 dc1.conf
-rw-------. 1 ceph ceph 159 Mar 21 11:52 dc2.client.admin.keyring
-rw-r--r--. 1 root root 632 Mar 21 11:52 dc2.conf
```

There are 2 ceph .conf files one for each cluster, and also two key-rings one for each cluster, to be able to run ceph commands on each of the clusters we have to use the --cluster option available on ceph cli commands, for example:


For our DC1 cluster:
```
[root@bastion ~]# ceph --cluster dc1 status
  cluster:
    id:     04e97e50-521d-4a25-8e46-dc9cc66fc7e2
    health: HEALTH_WARN
            too few PGs per OSD (16 < min 30)

  services:
    mon: 3 daemons, quorum cepha,cephb,cephc
    mgr: cephc(active), standbys: cepha
    osd: 6 osds: 6 up, 6 in
    rgw: 1 daemon active

  data:
    pools:   4 pools, 32 pgs
    objects: 219 objects, 1.09KiB
    usage:   6.05GiB used, 53.9GiB / 60.0GiB avail
    pgs:     32 active+clean

And for DC2 cluster:

[root@bastion ~]# ceph --cluster dc2 status
  cluster:
    id:     04e97e50-521d-4a25-8e46-dc9cc66fc7e2
    health: HEALTH_WARN
            too few PGs per OSD (16 < min 30)

  services:
    mon: 3 daemons, quorum ceph1,ceph2,ceph3
    mgr: ceph2(active), standbys: ceph1, ceph3
    osd: 6 osds: 6 up, 6 in
    rgw: 1 daemon active

  data:
    pools:   4 pools, 32 pgs
    objects: 219 objects, 1.09KiB
    usage:   6.03GiB used, 53.9GiB / 60.0GiB avail
    pgs:     32 active+clean
```

Information that we get from the status , command we can see that the cluster global heath is ok, in the services section we can see that we have 3 mons running on ceph1,ceph2,ceph3, and active manager currently running on ceph2 with 2 stanby nodes ceph1,ceph2 in case ceph2 fails. we have 6 osds, 2 osds per node(disks vdc,vdd), all the the 6 osds are up and in, we also have 1 rados gateway daemon running, finally on the data section we can see that 3 have 3 pools created, these 3 pools have a total 32 pgs used, we can see the current cluster usage at the moment 6GB out the 60gb we have available(each osd has 10gb, 2 osds per 3 nodes gives us our 60gb), and the 32 pgs are in active-clean state.


So with just one command we have a summary of our cluster state, we can dig a little bit deeper, for examle lets check what pools we have in the cluster and how much space they are using

We have 4 pools created on the installation by radosgw, the pools are replicated and the size is 3, which means that for each object that we write is replicated 2 times, so in total we will have 3 copies of the object.

```
[root@bastion ~]# ceph --cluster dc2  osd pool ls detail
pool 1 '.rgw.root' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 8 pgp_num 8 last_change 13 owner 18446744073709551615 flags hashpspool stripe_width 0 application rgw
pool 2 'default.rgw.control' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 8 pgp_num 8 last_change 16 owner 18446744073709551615 flags hashpspool stripe_width 0 application rgw
pool 3 'default.rgw.meta' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 8 pgp_num 8 last_change 18 owner 18446744073709551615 flags hashpspool stripe_width 0 application rgw
pool 4 'default.rgw.log' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 8 pgp_num 8 last_change 20 owner 18446744073709551615 flags hashpspool stripe_width 0 application rgw
```
How much space are they using, we can use the df command to get a summary of space usage per pool in the cluster:
```
[root@bastion ~]# ceph --cluster dc2  df
GLOBAL:
    SIZE        AVAIL       RAW USED     %RAW USED
    60.0GiB     53.9GiB      6.03GiB         10.06
POOLS:
    NAME                    ID     USED        %USED     MAX AVAIL     OBJECTS
    .rgw.root               1      1.09KiB         0       17.0GiB           4
    default.rgw.control     2           0B         0       17.0GiB           8
    default.rgw.meta        3           0B         0       17.0GiB           0
    default.rgw.log         4           0B         0       17.0GiB         207
```
We can check our osd cluster tree, were we can see that we have 2 osds under each host, with the default configuration each host is our failure domain, so ceph when doing the replication of the objects after a write will take care of replicating one copy of the object to and osd under each node.
```
[root@bastion ~]# ceph --cluster dc2 osd tree
ID CLASS WEIGHT  TYPE NAME      STATUS REWEIGHT PRI-AFF
-1       0.05878 root default                           
-5       0.01959     host ceph1                         
 0   hdd 0.00980         osd.0      up  1.00000 1.00000
 3   hdd 0.00980         osd.3      up  1.00000 1.00000
-7       0.01959     host ceph2                         
 2   hdd 0.00980         osd.2      up  1.00000 1.00000
 5   hdd 0.00980         osd.5      up  1.00000 1.00000
-3       0.01959     host ceph3                         
 1   hdd 0.00980         osd.1      up  1.00000 1.00000
 4   hdd 0.00980         osd.4      up  1.00000 1.00000
```
There is also the osd status command where we can see the status of the osds, disk usage per osd, and read/write ops taken place when the command is run.
[root@bastion ~]# ceph --cluster dc2 osd status
```
+----+-------------------------+-------+-------+--------+---------+--------+---------+-----------+
| id |           host          |  used | avail | wr ops | wr data | rd ops | rd data |   state   |
+----+-------------------------+-------+-------+--------+---------+--------+---------+-----------+
| 0  | ceph1.rhpds.opentlc.com | 1029M | 9206M |    0   |     0   |    0   |     0   | exists,up |
| 1  | ceph3.rhpds.opentlc.com | 1029M | 9206M |    0   |     0   |    0   |     0   | exists,up |
| 2  | ceph2.rhpds.opentlc.com | 1029M | 9206M |    0   |     0   |    0   |     0   | exists,up |
| 3  | ceph1.rhpds.opentlc.com | 1029M | 9206M |    0   |     0   |    0   |     0   | exists,up |
| 4  | ceph3.rhpds.opentlc.com | 1029M | 9206M |    0   |     0   |    0   |     0   | exists,up |
| 5  | ceph2.rhpds.opentlc.com | 1029M | 9206M |    0   |     0   |    0   |     0   | exists,up |
+----+-------------------------+-------+-------+--------+---------+--------+---------+-----------+
```
So once we have checked that both clusters are healthy and ready to be used, let's start with the configuration of our rgw multisite in the next exercise.
