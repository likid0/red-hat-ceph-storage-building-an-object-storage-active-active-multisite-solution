# Install and Configure DC2 Ceph cluster

On our bastion host we have ceph-ansible installed for us, because we are managing both of our Ceph clusters from one bastion host, 
we have one ceph-ansible directory per RHCS cluster:
```
[root@bastion ~]# ls -l /root/dc*
/root/dc1:
total 4
drwxr-xr-x. 7 root root 4096 Mar 19 11:35 ceph-ansible

/root/dc2:
total 0
drwxr-xr-x. 7 root root 272 Mar 19 11:35 ceph-ansible
```

We have our DC1 Ceph cluster already running, so now we are going to deploy our second cluster, to accomplish this we have to follow the following steps:

## Check DC2 Ansible inventory

Go into our ceph-ansible configuration dir for DC2 cluster:
```
[root@bastion ~]# cd ~/dc2/ceph-ansible/
```

We have a pre-defined inventory, with our Ceph nodes for our cluster in DC2.

As we have mentioned before we are going to run Ceph services (MON, MGR, OSD and RGW) on the same three Ceph nodes *ceph1*, *ceph2* and *ceph3*
We are also adding our Ceph nodes and the bastion host as clients so the ceph-keys get copied to the nodes and we can run Ceph commands from the bastion.
```
[root@bastion ~]# cat ~/dc2/ceph-ansible/inventory
[mons]
ceph[1:3]

[mgrs]
ceph[1:3]

[osds]
ceph[1:3]

[clients]
ceph[1:3]
bastion ansible_connection=local
metrics4

[ceph-grafana]
metrics4

[all:vars]
ansible_user=cloud-user
```

Run the following command to test the inventory and that Ansible connects ok to all nodes. All nodes in the inventory should respond to the Ansible ping module and there should be no errors.
```
[root@bastion ceph-ansible]# ansible -i inventory -m ping all
bastion | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
ceph2 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
ceph1 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
metrics4 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
ceph3 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
```

## Configure DC2 Ansible group_vars/

To configure our cluster using ceph-ansible we work with the variable files in `group_vars/`. These are the files that we have to take into account to configure our DC2 Ceph cluster for this lab:
```
[root@bastion ceph-ansible]# ls -l group_vars/ | grep -v sample
total 136
-rw-r--r--. 1 root root  1724 Mar 18 07:19 all.yml
-rw-r--r--. 1 root root  1927 Mar 18 06:38 clients.yml
-rw-r--r--. 1 root root  1558 Mar 18 06:30 mgrs.yml
-rw-r--r--. 1 root root   257 Mar 18 07:19 osds.yml
-rw-r--r--. 1 root root   929 Mar 18 06:55 rgws.yml
```

There are 2 yml files that we have to modify, so we can configure our DC2 Ceph cluster as needed:
* osds.yml
* all.yml

> **NOTE**: Be careful with indentation and only modify the parameters mentioned. Syntax errors may lead to cluster misconfiguration which could damage the cluster.

First we are going to configure the OSDs. We need to edit the file and do the following modifications:
- Specify `lvm` as the `osd_scenario`
- There are several scenarios available:
 - non-colocated
 - colocated
 - lvm

```
[root@bastion ceph-ansible]# vim group_vars/osds.yml
#valid_osd_scenarios:
osd_scenario: lvm
```

We have the option to create several OSDs per disk, but we are going to configure 1 OSD per disk:
```
[root@bastion ceph-ansible]# vim group_vars/osds.yml
# Number of OSDS per drive that we want to configure
osds_per_device: 1
```

Finally we have to specify the devices on our Ceph nodes that we want to configure as OSDs.

We are going to connect to one of our Ceph nodes, and check the disks we have available, we should have x2 10GB disks to configure our OSDs:
```
[root@bastion ceph-ansible]# ssh cloud-user@ceph1 "lsblk | grep 10G"
vdc                   253:32   0   10G  0 disk
vdd                   253:48   0   10G  0 disk
```

Once we know that we have vdc and vdd, we add them our osds.yml file:

> ** NOTE **: Make sure to also uncomment the line with "devices:" as shown in the example below

```
[root@bastion ceph-ansible]# vim group_vars/osds.yml
# Declare devices to be used as OSDs
devices:
  - /dev/vdc
  - /dev/vdd
```

Now we can move on to the next vars file that is `all.yml`. This is the main config file for the cluster, we need to edit the file and make the following modifications.

Change the cluster name, we are going to name are second cluster dc2:
```
[root@bastion ceph-ansible]# vim group_vars/all.yml
#The 'cluster' variable determines the name of the cluster.
cluster: dc2
```

We are going to configure bluestore as our object store:
```
[root@bastion ceph-ansible]# vim group_vars/all.yml
# We can configure filestore or bluestore as our objecstore
osd_objectstore: bluestore
```

We are going to define the monitor_interface variable to our public network eth0:
```
[root@bastion ceph-ansible]# vim group_vars/all.yml
monitor_interface: eth0
```

Add the public and cluster networks for dc2, if you check in the network schema for our lab we can see that the public network is `172.16.0.0/24` and the private network where Ceph replication will happen is `192.168.1.0/24`.
```
[root@bastion ceph-ansible]# vim group_vars/all.yml
#Ceph Cluster network config###
public_network:  172.16.0.0/24
cluster_network: 192.168.1.0/24
```

For the containerized configuration we will use RHCS3 image `rhceph-3-rhel7:latest`, and we have to configure the registry from where we want to pull the container image, 
the registry for DC2 has the IP 172.16.0.10, listening on port 5000.
```
[root@bastion ceph-ansible]# vim group_vars/all.yml
###Containerized Configuration###
containerized_deployment: true
ceph_docker_image: "rhceph/rhceph-3-rhel7"
ceph_docker_image_tag: "latest"
ceph_docker_registry: "172.16.0.10:5000"
docker_pull_retry: 6
docker_pull_timeout: "600s"
```

Finally, we have to configure on what interface we want to have the RGW service listening. We configure our public network interface which is eth0.
```
[root@bastion ceph-ansible]# vim group_vars/all.yml
radosgw_interface: eth0
```

With the rest of the files, just to point out some config options.

For the Ceph MGR daemon, we add the prometheus manager plugin, this is needed to get ceph-metrics working:
```
[root@bastion ceph-ansible]# vim group_vars/mgrs.yml
ceph_mgr_modules: [status,dashboard,prometheus]
```

For the client, the `copy_admin_key` variable means that we copy the admin key to the nodes that are included in the clients group of our inventory
```
[root@bastion ceph-ansible]# vim group_vars/clients.yml
copy_admin_key: true
```

## Run ceph-ansible installer!!

With all the variables ready we can start the deployment of the Ceph cluster.

> WARNING: before running the installation we recommend using screen or tmux to avoid problems in case there are network issues.

On the root of the ceph-ansible dir /root/dc2/ceph-ansible we need to run the `site-docker.yml` playbook.
```
[root@bastion ~]# cd ~/dc2/ceph-ansible
[root@bastion ceph-ansible]# cp site-docker.yml.sample site-docker.yml
[root@bastion ceph-ansible]# ansible-playbook -i inventory site-docker.yml
```

The installation will take approximately 10 minutes, if the installation has finished successfully, you will see the Ansible summary with 0 errors:
```
PLAY RECAP ******************************************************************
bastion                    : ok=67   changed=5    unreachable=0    failed=0   
ceph1                      : ok=508  changed=47   unreachable=0    failed=0   
ceph2                      : ok=319  changed=34   unreachable=0    failed=0   
ceph3                      : ok=321  changed=35   unreachable=0    failed=0   
metrics4                   : ok=67   changed=6    unreachable=0    failed=0   
```

> INFO: If you need to delete your cluster you can use the purge-docker-cluster.yml available in ceph ansible.

> WARNING!!: this will delete all the config and pools in your cluster only use if something has gone very wrong.

> For Example to delete/purge the DC2 ceph cluster you would run the next 2 commands:

```
[root@bastion]# cd /root/dc2/ceph-ansible/
[root@bastion ceph-ansible]# ansible-playbook -i inventory --skip-tags=with_pkg purge-docker-cluster.yml

```


## Check both DC1 and DC2 cluster health

With our DC2 cluster installed, let's check the status of both of our clusters and briefly overview there configuration.

Because we configured the bastion host as a client we should have the ceph admin keys available in `/etc/ceph`:
```
[root@bastion ~]# ls -l /etc/ceph/
total 20
-rw-------. 1 ceph ceph 159 Mar 19 11:49 dc1.client.admin.keyring
-rw-r--r--. 1 root root 624 Mar 19 11:49 dc1.conf
-rw-------. 1 ceph ceph 159 Mar 21 11:52 dc2.client.admin.keyring
-rw-r--r--. 1 root root 632 Mar 21 11:52 dc2.conf
-rw-r--r--. 1 root root  92 Feb 28 11:34 rbdmap
```

There are two different `ceph.conf` files, one for each cluster and also two different keyrings one for each cluster.
To be able to run ceph commands on each of the clusters we have to use the --cluster option available on ceph cli commands, for example:

### Check both cluster status

For our DC1 cluster:
```
[root@bastion ~]# ceph --cluster dc1 status
  cluster:
    id:     e5218b18-4f23-4b8a-b259-dcc5fce717ab
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum cepha,cephb,cephc
    mgr: cephb(active), standbys: cepha, cephc
    osd: 6 osds: 6 up, 6 in
 
  data:
    pools:   0 pools, 0 pgs
    objects: 0 objects, 0B
    usage:   6.02GiB used, 54.0GiB / 60.0GiB avail
    pgs:
```

And for DC2 cluster:
```
[root@bastion ~]# ceph --cluster dc2 status
  cluster:
    id:     e5218b18-4f23-4b8a-b259-dcc5fce717ab
    health: HEALTH_OK
 
  services:
    mon: 3 daemons, quorum ceph1,ceph2,ceph3
    mgr: ceph1(active), standbys: ceph2, ceph3
    osd: 6 osds: 6 up, 6 in
 
  data:
    pools:   0 pools, 0 pgs
    objects: 0 objects, 0B
    usage:   6.02GiB used, 54.0GiB / 60.0GiB avail
    pgs: 
```

Information that we get from the status command, we can see that the cluster global heath is `ok`. In the services section we can see that we have three MONs running on *ceph1*, *ceph2* and *ceph3* and active manager currently running on *ceph2* with 2 `standby` nodes *ceph1* and *ceph3* in case *ceph2* fails.

We have also 6 OSDs, 2 OSDs per node(disks vdc and vdd). All six OSDs are `up` and `in`; We can also see three RadosGW daemons running.

Finally on the data section, we still don't have any pools created, once we install RGW we will see that several pools get created during deployment.



### Check both clusters OSDs

We can check our OSD cluster tree were we can see that we have 2 OSDs under each host.
With the default configuration each host is our failure domain. It means Ceph when doing the replication of the objects after a write, will take care of replicating one copy of the object to an OSD under each node.
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

There is also the OSD status command where we can see the status of the OSDs, disk usage per OSD, and read/write ops taken place when the command is run.
```
[root@bastion ~]# ceph --cluster dc2 osd status
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

So once we have checked that both clusters are healthy and ready to be used, let's start with the configuration of our RGW multisite.

## [**Next: RGW Configuration**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/scenario2/02-RadosGW_configuration)

## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
