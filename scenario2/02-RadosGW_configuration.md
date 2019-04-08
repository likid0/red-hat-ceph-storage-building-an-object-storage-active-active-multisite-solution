# RGWs Configuration in Both Clusters

RGWs are already running, but we have to configure both the zone and zonegroup in each cluster. 
This step is mandatory before we can start configuring the multi-site.

All RGWs services SHOULD BE STOPPED before following this procedure to create realms, zonegroups and zones.
More info can be found in the [Red Hat Ceph Storage Object Gateway Guide For RHEL](https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/3/html-single/object_gateway_guide_for_red_hat_enterprise_linux/index)

Because we haven't install rados gateway yet, from the bastion host we can check that RGWs containers are not running in DC1 and DC2 nodes
```
[root@bastion ~]# ansible -b -m shell -a "docker ps | grep rgw" ceph1,cepha
cepha | FAILED | rc=1 >>
non-zero return code
ceph1 | FAILED | rc=1 >>
non-zero return code
```

Just in case you have installed RGW, we can use the systemd unit to stop RGWs containers, before we continue
```
[root@bastion ~]#  ansible -b -m shell -a "systemctl stop ceph-radosgw@rgw.ceph*" ceph1,cepha
cepha | SUCCESS | rc=0 >>
ceph1 | SUCCESS | rc=0 >>

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
    rgw dns name: s3.dc1.summit.lab
  client.rgw.cephb:
    host: cephb
    keyring: /var/lib/ceph/radosgw/ceph-rgw.cephb/keyring
    log file: /var/log/ceph/ceph-rgw-cephb.log
    rgw frontends: civetweb port=10.0.0.12:8080 num_threads=1024
    rgw_dynamic_resharding: false
    debug_civetweb: "0/1"
    rgw_enable_apis: s3,admin
    rgw_zone: dc1
    rgw_thread_pool_size: 1024
    rgw dns name: s3.dc1.summit.lab
  client.rgw.cephc:
    host: cephc
    keyring: /var/lib/ceph/radosgw/ceph-rgw.cephc/keyring
    log file: /var/log/ceph/ceph-rgw-cephc.log
    rgw frontends: civetweb port=10.0.0.13:8080 num_threads=1024
    rgw_dynamic_resharding: false
    debug_civetweb: "0/1"
    rgw_enable_apis: s3,admin
    rgw_zone: dc1
    rgw_thread_pool_size: 1024
    rgw dns name: s3.dc1.summit.lab
```

```
# vim /root/dc1/ceph-ansible/group_vars/rgws.yml
```

```
ceph_rgw_docker_extra_env: "-e RGW_ZONE=dc1 -e RGW_ZONEGROUP=production"
```

Once modified we have to run the site-docker playbook again for DC1. However all changes mentioned above are exclusively related to rgw. In this case the -l option can be used to limit the playbook execution to rgws hostgroup.

```
# cd /root/dc1/ceph-ansible/
# ansible-playbook -i inventory site-docker.yml -l rgws
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
    rgw dns name: s3.dc2.summit.lab
  client.rgw.ceph2:
    host: ceph2
    keyring: /var/lib/ceph/radosgw/ceph-rgw.ceph2/keyring
    log file: /var/log/ceph/ceph-rgw-ceph2.log
    rgw frontends: civetweb port=172.16.0.12:8080 num_threads=1024
    rgw_dynamic_resharding: false
    debug_civetweb: "0/1"
    rgw_enable_apis: s3,admin
    rgw_zone: dc2
    rgw_thread_pool_size: 1024
    rgw dns name: s3.dc2.summit.lab
  client.rgw.ceph3:
    host: ceph3
    keyring: /var/lib/ceph/radosgw/ceph-rgw.ceph3/keyring
    log file: /var/log/ceph/ceph-rgw-ceph3.log
    rgw frontends: civetweb port=172.16.0.13:8080 num_threads=1024
    rgw_dynamic_resharding: false
    debug_civetweb: "0/1"
    rgw_enable_apis: s3,admin
    rgw_zone: dc2
    rgw_thread_pool_size: 1024
    rgw dns name: s3.dc2.summit.lab
```

```
# vim /root/dc2/ceph-ansible/group_vars/rgws.yml
ceph_rgw_docker_extra_env: "-e RGW_ZONE=dc2 -e RGW_ZONEGROUP=production"
```

You can see we are setting the same zonegroup "production" for the two clusters, while zone is gonna be different, DC1 and DC2.
```
#cd /root/dc2/ceph-ansible/
#ansible-playbook -i inventory site-docker.yml -l rgws
```

Once the playbook run finishes on both clusters, you should have 0 errors in the play recap of both clusters
```
PLAY RECAP ************************************************************************************************************************************************************************************************************************************
cepha                      : ok=516  changed=30   unreachable=0    failed=0   
cephb                      : ok=413  changed=25   unreachable=0    failed=0   
cephc                      : ok=416  changed=26   unreachable=0    failed=0   
```

You won't see your RadosGW service listed in the ceph status command, don't worry this is normal, we have configured our rados gw services as part of a Realm/Zone that currently don't exist, thats why the RGW service doesn't start, in the next section we are going to create the realm,zonegroup and zones, then we can check that our Rados Gatewat Daemons are running like expected.
```
[root@bastion ceph-ansible]# ceph --cluster dc1 -s | grep rgw
[root@bastion ceph-ansible]# 
```


## [**Next: RGW Multisite Configuration**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/scenario3/03-RadosGW_Multisite_Configuration)

## Sources

* [Red Hat Ceph Storage Object Gateway Guide For RHEL](https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/3/html-single/object_gateway_guide_for_red_hat_enterprise_linux/index)

## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
