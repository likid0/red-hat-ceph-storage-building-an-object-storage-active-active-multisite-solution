## Installing Ceph-metrics in DC2 ceph cluster.

We need to ssh to our metrics virtual machine in DC2, it's hostname is `metrics4`.
```
[root@bastion ~]# ssh cloud-user@metrics4
Warning: Permanently added 'metrics4,172.16.0.14' (ECDSA) to the list of known hosts.
Last login: Fri Mar 22 18:49:10 2019 from 172.16.0.10
[cloud-user@metrics4 ~]$ sudo -i
```

We have `cephmetrics-ansible` already pre-installed on the system, lets check it:
```
[root@metrics4 ~]# yum list installed | grep -i cephmetrics
cephmetrics-ansible.x86_64       2.0.2-1.el7cp               @rhel-7-server-rhceph-3-tools-rpms

```

The ansible playbooks are stored in `/usr/share/cephmetrics-ansible/`.
```
[root@metrics4 ~]# cd /usr/share/cephmetrics-ansible/
[root@metrics4 cephmetrics-ansible]# ls
ansible.cfg  group_vars  inventory  inventory.sample  playbook.yml  purge.yml  README.md  roles
```

Lets check the `group_vars/all.yml` variable file, here we can specify the name of the cluster, if we want to do a containerized deployment, were is our registry and also specify the Grafana users to access the metrics dashboard.

To try and save some time, the inventory and the variables have already been pre-configured for you.
```
[root@metrics4 cephmetrics-ansible]# cat group_vars/all.yml
dummy:

cluster_name: dc2

containerized: true

# Set the backend options, mgr+prometheus or cephmetrics+graphite
#backend:
#  metrics: mgr  # mgr, cephmetrics
#  storage: prometheus  # prometheus, graphite

# Turn on/off devel_mode
#devel_mode: true

# Set grafana admin user and password
# You need to change these in the web UI on an already deployed machine, first
# New deployments work fine
grafana:
  admin_user: admin
  admin_password: redhat01
  container_name: 172.16.0.10:5000/rhceph/rhceph-3-dashboard-rhel7
prometheus:
  container_name: 172.16.0.10:5000/openshift3/prometheus
  etc_hosts:
    172.16.0.11: ceph1.summit.lab
    172.16.0.12: ceph2.summit.lab
    172.16.0.13: ceph3.summit.lab
    172.16.0.14: metrics4.summit.lab
```

We can now run the installation playbook.
```
[root@metrics4 cephmetrics-ansible]# ansible-playbook -i inventory playbook.yml
```

If everything has gone fine during the installation you should see an Ansible playbook recap similar to this one, with no errors.
```
PLAY RECAP ************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************
ceph1                      : ok=22   changed=4    unreachable=0    failed=0   
ceph2                      : ok=13   changed=2    unreachable=0    failed=0   
ceph3                      : ok=13   changed=2    unreachable=0    failed=0   
localhost                  : ok=1    changed=0    unreachable=0    failed=0   
metrics4                   : ok=76   changed=19   unreachable=0    failed=0   
```

We can now go to a browser on your lab laptop and connect to the Grafana dashboard, running in `metrics4` host.

> NOTE: On the provided URL you have to replace GUID with the GUID assigned to your lab.

> NOTE: You will have to use http, to keep it simple we are not using ssl.

|    Param  | Configuration    |
| :------------- | :------------- |
| URL       | http://metrics4-GUID.rhpds.opentlc.com:3000   |
| User | admin |
|Password | redhat01 |

Once you have entered the Grafana credentials, you will be presented with the ceph-metrics landing page.

<center><img src="scenario5/images/01cephmetrics-ataglance.png" style="width:1200px;" border=0/></center>

On the upper left of the page where it says Ceph At A Glance, you can access all the different ceph-metrics dashboards available, please take some time to explore.

<center><img src="scenario5/images/02cephmetrics-dashboards.png" style="width:1200px;" border=0/></center>

Now that you are familiar with some of the ceph-metrics dashboards, lets put some objects into the cluster and see how it's represented in Grafana.

First lets open the the "ceph storage backend" dashboard, and expand the "Disk/OSD Load" Summary and the "OSD Host CPU and Network Load" bullets

<center><img src="scenario5/images/03cephmetrics-backends.png" style="width:1200px;" border=0/></center>

From the bastion host we are going to create a 3GB file and upload it to our DC2 cluster; Then we will download it several times, once the file starts downloading we can switch to Grafana and see how the metrics vary. We should see the total throughput and IOPs increase.
```
[root@bastion ~]# fallocate -l 3G testfile
[root@bastion ~]# s3cmd -c ~/s3-dc2.cfg  put testfile  s3://my-second-bucket
[root@bastion ~]# for i in 1 2 3 4 5; do s3cmd -c ~/s3-dc2.cfg  get  s3://my-second-bucket/testfile --force; done
```

Also check via the `radosgw-admin` cli that the DC1 zone is doing a sync to keep up with changes in DC2.
```
[root@bastion ~]# radosgw-admin  --cluster dc1 sync status
          realm 80827d79-3fce-4b55-9e73-8c67ceab4f73 (summitlab)
      zonegroup 88222e12-006a-4cac-a5ab-03925365d817 (production)
           zone 602f21ea-7664-4662-bad8-0c3840bb1d7a (dc1)
  metadata sync no sync (zone is master)
      data sync source: ed9f1807-7bc8-48c0-b82f-0fa1511ba47b (dc2)
                        syncing
                        full sync: 0/128 shards
                        incremental sync: 128/128 shards
                        1 shards are recovering
                        recovering shards: [52]
```

From the Grafana ceph-metrics dashboard select the "Ceph Pools" dashboard, You will be able to see the troughput and IOPs per pool, and we can see that the busiest pool is the `dc2.rgw.buckets.data`. For example You can also check the TOP 5 pools by capacity used.

<center><img src="scenario5/images/04cephmetrics-pools.png" style="width:1200px;" border=0/></center>


We can also see with the CLI `ceph df` command how our total storage available for both clusters has decreased after we have uploaded the 3gb file from DC2 and it has got replicated to DC1.

```
[root@bastion ~]# ceph --cluster dc2  df | head -3
GLOBAL:
    SIZE        AVAIL       RAW USED     %RAW USED
    60.0GiB     43.6GiB      16.4GiB         27.30
[root@bastion ~]# ceph --cluster dc1  df | head -3
GLOBAL:
    SIZE        AVAIL       RAW USED     %RAW USED
    60.0GiB     43.6GiB      16.4GiB         27.30
```
## [**Next:Extra Lab. S3 Policy**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/scenario6/06-S3_policies)
## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
