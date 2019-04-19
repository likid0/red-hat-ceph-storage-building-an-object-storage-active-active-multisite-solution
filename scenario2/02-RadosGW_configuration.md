# RGWs Configuration in Both Clusters

We are going to deploy the RadosGW service on the 3 nodes we have per-cluster, once we have our RadosGW services running on each cluster we will be ready to starte the multi-site configuration.



As we mentioned before we are going to make use of ceph-ansible to deploy and configure the RadosGW servives, we have to do some modifications to the ceph-ansible group vars to achive our goal:


## Configure RGWs in DC1

Edit the all.yml file in ceph-ansible node for DC1 and add the following lines to the override section:
 ```
[root@bastion ~]# vim ~/dc1/ceph-ansible/group_vars/all.yml
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
```

**NOTE: This is no longer needed with recent ceph versions. It was only needed with Ceph 3.0**
```
[root@bastion ~]# vim /root/dc1/ceph-ansible/group_vars/rgws.yml
```

```
ceph_rgw_docker_extra_env: "-e RGW_ZONE=dc1 -e RGW_ZONEGROUP=production"
```

Before executing the ansible playbook, we need to check if our 3 nodes are listed in the [rgws] group. In DC1 one they have already been added for us.

```
[root@bastion ~]# vim ~/dc1/ceph-ansible/inventory
[mons]
ceph[a:c]

[mgrs]
ceph[a:c]

[osds]
ceph[a:c]

[clients]
ceph[a:c]
bastion ansible_connection=local
metricsd

[ceph-grafana]
metricsd

[rgws]
ceph[a:c]

[all:vars]
ansible_user=cloud-user
```

Once modified we have to run the site-docker playbook again for DC1. However all changes mentioned above are exclusively related to the RadosGW service. In this case the -l option can be used to limit the playbook execution to rgws hostgroup.

```
[root@bastion ~]# cd ~/dc1/ceph-ansible/
[root@bastion ceph-ansible]# ansible-playbook -i inventory site-docker.yml -l rgws
PLAY RECAP ****************************************************************
cepha                      : ok=516  changed=30   unreachable=0    failed=0   
cephb                      : ok=413  changed=25   unreachable=0    failed=0   
cephc                      : ok=416  changed=26   unreachable=0    failed=0
```

## Configure RGWs in DC2

We have to follow the same steps on our second cluster in DC2:
```
[root@bastion ~]# vim ~/dc2/ceph-ansible/group_vars/all.yml
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
```

**NOTE: This is no longer needed with recent ceph versions. It was only needed with Ceph 3.0**
```
# vim /root/dc2/ceph-ansible/group_vars/rgws.yml
ceph_rgw_docker_extra_env: "-e RGW_ZONE=dc2 -e RGW_ZONEGROUP=production"
```

We now have to modify the inventory so we can add our 3 ceph nodes under the [rgws] group section:
```
[root@bastion ceph-ansible]# cd /root/dc2/ceph-ansible
[root@bastion ceph-ansible]# cat inventory 
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

[rgws]
ceph[1:3]

[all:vars]
ansible_user=cloud-user

```


Once modified we have to run the site-docker playbook again for DC2. However all changes mentioned above are exclusively related to the RadosGW service. In this case the -l option can be used to limit the playbook execution to rgws hostgroup.

```
[root@bastion ~]# cd ~/dc2/ceph-ansible/
[root@bastion ceph-ansible]# ansible-playbook -i inventory site-docker.yml -l rgws
PLAY RECAP ****************************************************************
ceph1                      : ok=513  changed=28   unreachable=0    failed=0   
ceph2                      : ok=410  changed=23   unreachable=0    failed=0   
ceph3                      : ok=413  changed=24   unreachable=0    failed=0
```

>**NOTE:** You will not see your RadosGW service listed in the Ceph status command but don't worry this is normal. We have configured our RadosGW services as part of a Realm/Zone that do not exist yet, that is why the RadosGW service does not start. In the next section we are going to create the realm,zonegroup and zones, then we can check that our RadosGW daemons are running like expected.
```
[root@bastion ceph-ansible]# ceph --cluster dc1 -s | grep rgw
[root@bastion ceph-ansible]# 
[root@bastion ceph-ansible]# ceph --cluster dc2 -s | grep rgw
[root@bastion ceph-ansible]#
```


## [**Next: RGW Multisite Configuration**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/scenario3/03-RadosGW_Multisite_Configuration)

## Sources

* [Red Hat Ceph Storage Object Gateway Guide For RHEL](https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/3/html-single/object_gateway_guide_for_red_hat_enterprise_linux/index)

## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
