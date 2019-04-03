# Install and Configure DC2 Ceph cluster

On our bastion host we have ceph-ansible installed for us, because we are managing both of our Ceph clusters from one bastion host, we have one ceph-ansible dir per Ceph cluster:

```
ls -l /root/dc*
```

We have our DC1 Ceph cluster already running, so now we are going to deploy our second cluster, to accomplish this we have to follow the following steps:

## Check DC2 Ansible inventory

Go into our ceph-ansible configuration dir for DC2 cluster:
```
cd /root/dc2/ceph-ansible
```

We have a pre-defined inventory, with our Ceph nodes for our cluster in DC2.

Like we have mentioned before we are going to run the MONs, MGRs, OSDs on the 3 ceph nodes ceph1,2,3.
We are also adding our Ceph nodes and the bastion host as clients so the ceph-keys get copied to the nodes and we can run Ceph commands from the bastion.

Finally we will configure a RGW service to run on ceph1 node.
```
cat /root/dc2/ceph-ansible/inventory
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

Run the following command to test the inventory and that Ansible connects ok to all nodes. All nodes in the inventory should respond to the Ansible ping module and there should be no errors.

```
ansible -i inventory -m ping all
```
## Configure DC2 Ansible group_vars/

To configure our cluster using ceph-ansible we work with the variable files in group_vars/, These are the files that we have to take in account to configure our DC2 Ceph cluster for this lab:

```
ls -l group_vars/ | grep -v sample
```

There are 2 yml files that we have to modify, so we can configure our DC2 cluster as needed:
* osds.yml
* all.yml

>**NOTE**: Be careful with indentation and only modify the parameters mentioned. Syntax errors may lead to cluster misconfiguration which could damage the cluster.

First we are going to configure the OSDs. We need to edit the file and do the following modifications, specify lvm as the osd_scenario, there are several scenarios available `non-colocated`, `colocated` and `lvm`, in our case we are going to use `lvm`:

```
cat group_vars/osds.yml | grep osd_scenario
#valid_osd_scenarios:
osd_scenario: lvm
```

We have the option to create several OSDs per disk, but we are going to configure 1 OSD per disk:
```
# cat group_vars/osds.yml  | grep osds
osds_per_device: 1
```

Finally we have to specify the devices on our Ceph nodes that we want to configure as OSDs.

We are going to connect to one of our Ceph nodes, and check the disks we have available, we should have x2 10GB disks to configure our OSDs:

```
ssh  cloud-user@ceph1 "lsblk | grep 10G"
```

Once we now that we have vdc and vdd, we add them our osds.yml file:
```
cat osds.yml | tail -3
devices:
  - /dev/vdc
  - /dev/vdd
```

Now we can move on to the next vars file that is all.yml, this is the main config file for the cluster, we need to edit the file and make the following modifications.


Change the cluster name, we are going to name are second cluster dc2:

```
cat /root/dc2/ceph-ansible/group_vars/all.yml | grep "cluster:"
cluster: dc2
```

We are going to configure bluestore as our objecstore:
```
cat all.yml | grep -i osd_objectstore
osd_objectstore: bluestore
```

We are going to define the monitor_interface variable to our public network eth0:
```
cat all.yml | grep  monitor_interface
monitor_interface: eth0
```

Add the public and cluster networks for dc2, if you check in the network schema for our lab we can see that the public network is `172.16.0.0/24` and the private network where Ceph replication will happen is `192.168.1.0/24`.
```
cat /root/dc2/ceph-ansible/group_vars/all.yml | grep network
#Ceph Cluster network config###
public_network:  172.16.0.0/24
cluster_network: 192.168.1.0/24
```

For the containerized configuration we will use Ceph 3 image `rhceph-3-rhel7:latest`, and we have to configure the registry from where we want to pull the container image, the registry for DC2 has the IP 172.16.0.10, listening on port 5000.
```
###Containerized Configuration###
containerized_deployment: true
ceph_docker_image: "rhceph/rhceph-3-rhel7"
ceph_docker_image_tag: "latest"
ceph_docker_registry: "172.16.0.10:5000"
docker_pull_retry: 6
docker_pull_timeout: "600s"
```

Finally, we have to configure on what interface we want to have the RGW listening; We are configuring our public network interface.

```
cat /root/dc2/ceph-ansible/group_vars/all.yml | grep radosgw_interface
radosgw_interface: eth0
```

With the rest of the files, just to point out some config options

For the Ceph MGR daemon, we add the prometheus manager plugin, this is needed to get ceph-metrics working:
```
cat mgrs.yml | grep -i ceph_mgr_modules
ceph_mgr_modules: [status,dashboard,prometheus]
```

For the client, the copy_admin_key variable means that we copy the admin key to the nodes that are included in the clients group of our inventory
```
cat clients.yml | grep admin_key
copy_admin_key: true
```

## Run ceph-ansible installer!!

With all the variables ready we can start the deployment of the Ceph cluster, on the root of the ceph-ansible dir /root/dc2/ceph-ansible we need to run the site-docker.yml playbook.
```
cd /root/dc2/ceph-ansible
cp site-docker.yml.sample site-docker.yml
ansible-playbook -i inventory site-docker.yml
```

The installation will take approximately 10 minutes, if the installation has finished successfully you will see the Ansible summary with 0 errors:
```
PLAY RECAP ************************************************************************************************************************************************************************************************************************************
0bastion                   : ok=67   changed=5    unreachable=0    failed=0   
ceph1                      : ok=508  changed=47   unreachable=0    failed=0   
ceph2                      : ok=319  changed=34   unreachable=0    failed=0   
ceph3                      : ok=321  changed=35   unreachable=0    failed=0   
metrics4                   : ok=67   changed=6    unreachable=0    failed=0   
```

## Check both DC1 and DC2 cluster health

With our DC2 cluster installed, lets check the status of both of our clusters and briefly overview there configuration.

Because we configured the bastion host as a client we should have the ceph admin keys available in /etc/ceph:
```
ls -l /etc/ceph/
```

There are 2 Ceph .conf files one for each cluster, and also two key-rings one for each cluster. To be able to run ceph commands on each of the clusters we have to use the --cluster option available on ceph cli commands, for example:

### Check both cluster status

For our DC1 cluster:
```
ceph --cluster dc1 status
```

And for DC2 cluster:
```
ceph --cluster dc2 status
```

Information that we get from the status command, we can see that the cluster global heath is `ok`. In the services section we can see that we have 3 mons running on ceph1,ceph2,ceph3, and active manager currently running on ceph2 with 2 `stanby` nodes ceph1,ceph2 in case ceph2 fails. 

We have also 6 OSDs, 2 OSDs per node(disks vdc,vdd), all the the 6 OSDs are `up` and `in`; We also can see 1 RGW daemon running. 

Finally on the data section we can see that 3 have 3 pools created, these 4 pools have a total 32 pgs (Placement Groups) used, we can see the current cluster usage at the moment is 6GB out the 60gb we have available(each OSD has 10gb, 2 ODSs per 3 nodes gives us our 60gb), and the 32 pgs are in `active-clean` state.

### Check both clusters pools

So with just one command we have a summary of our cluster state, we can dig a little bit deeper, for examle lets check what pools we have in the cluster and how much space they are using

We have 4 pools created on the installation by RGW, the pools are replicated and the size is 3, which means that for each object that we write is replicated 2 times, so in total we will have 3 copies of the object.

```
ceph --cluster dc2  osd pool ls detail
```

### Check both clusters available space

How much space are they using, we can use the df command to get a summary of space usage per pool in the cluster:
```
ceph --cluster dc2  df
```

### Check both clusters OSDs

We can check our OSD cluster tree, were we can see that we have 2 OSDs under each host, with the default configuration each host is our failure domain; It means Ceph when doing the replication of the objects after a write, will take care of replicating one copy of the object to and OSD under each node.
```
ceph --cluster dc2 osd tree
```

There is also the OSD status command where we can see the status of the OSDs, disk usage per OSD, and read/write ops taken place when the command is run.
```
ceph --cluster dc2 osd status
```

So once we have checked that both clusters are healthy and ready to be used, let's start with the configuration of our rgw multisite.

## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
