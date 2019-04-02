# RGWs Configuration in Both Clusters

RGWs are already running, but we have to configure both the zone and zonegroup in each cluster. 
This step is mandatory before we can start configuring the multi-site.

All RGWs services SHOULD BE STOPPED before following this procedure to create realms, zonegroups and zones.
More info can be found in the [Red Hat Ceph Storage Object Gateway Guide For RHEL](https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/3/html-single/object_gateway_guide_for_red_hat_enterprise_linux/index)

From the bastion host we can check that RGWs containers are running on cepha (DC1) and ceph1 (DC2) nodes.
```
[root@bastion ~]# ansible -b -m shell -a "docker ps | grep rgw" ceph1,cepha
cepha | SUCCESS | rc=0 >>
883549d1226c        10.0.0.10:5000/rhceph/rhceph-3-rhel7:latest   "/entrypoint.sh"    4 hours ago         Up 4 hours                              ceph-rgw-cepha

ceph1 | SUCCESS | rc=0 >>
dcd14c2e0b54        172.16.0.10:5000/rhceph/rhceph-3-rhel7:latest   "/entrypoint.sh"    4 hours ago         Up 4 hours                              ceph-rgw-ceph1
```

We are going to use the systemd unit to stop RGWs containers.
```
[root@bastion ~]#  ansible -b -m shell -a "systemctl stop ceph-radosgw@rgw.ceph*" ceph1,cepha
cepha | SUCCESS | rc=0 >>


ceph1 | SUCCESS | rc=0 >>

```
And finally double check so we are sure our containers are stopped.

```
[root@bastion ~]# ansible -b -m shell -a "docker ps | grep rgw" ceph1,cepha
cepha | FAILED | rc=1 >>
non-zero return code

ceph1 | FAILED | rc=1 >>
non-zero return code
```

We have to do some modifications on the ceph.conf of all the RGWs nodes so we can specify the zone for each RGW daemon.
We are going to make use of ceph-ansible to implement these changes.

## Configure RGWs in DC1

Edit the all.yml file in Ceph-ansible node for DC1:
 ```
# vim /root/dc1/ceph-ansible/group_vars/all.yml
```
And add the following to the override section:
```
  client.rgw.cepha:
    host: cepha
    keyring: /var/lib/ceph/radosgw/ceph-rgw.cepha/keyring
    log file: /var/log/ceph/ceph-rgw-cepha.log
    rgw frontends: civetweb port=10.0.0.11:8080 num_threads=1024
    rgw_dynamic_resharding: false
    debug_civetweb: "0/1"
    rgw_enable_apis: s3,admin
    rgw_zone: dc1
    rgw_thread_pool_size: 1024
```
```
# vim /root/dc1/ceph-ansible/group_vars/rgws.yml
```
```
ceph_rgw_docker_extra_env: "-e RGW_ZONE=dc1 -e RGW_ZONEGROUP=production"
```

Once modified we have to run the site-docker playbook again for DC1:
```
# cd /root/dc1/ceph-ansible/
# ansible-playbook site-docker.yml
```
## Configure RGWs in DC2

We have to follow the same steps on our second cluster in DC2:
```
# vim /root/dc2/ceph-ansible/group_vars/all.yml
  client.rgw.ceph1:
    host: ceph1
    keyring: /var/lib/ceph/radosgw/ceph-rgw.ceph1/keyring
    log file: /var/log/ceph/ceph-rgw-ceph1.log
    rgw frontends: civetweb port=172.16.0.11:8080 num_threads=1024
    rgw_dynamic_resharding: false
    debug_civetweb: "0/1"
    rgw_enable_apis: s3,admin
    rgw_zone: dc2
    rgw_thread_pool_size: 1024
```
```
# vim /root/dc2/ceph-ansible/group_vars/rgws.yml
ceph_rgw_docker_extra_env: "-e RGW_ZONE=dc2 -e RGW_ZONEGROUP=production"
```
You can see we are setting the same zonegroup "production" for the two clusters, while zone is gonna be different, DC1 and DC2.

```
#cd /root/dc2/ceph-ansible/
#ansible-playbook site-docker.yml
```

## Sources

* [Red Hat Ceph Storage Object Gateway Guide For RHEL](https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/3/html-single/object_gateway_guide_for_red_hat_enterprise_linux/index)

## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)