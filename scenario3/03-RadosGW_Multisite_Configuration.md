# Rados Gateway Active-Active Multisite Configuration

A single zone configuration typically consists of one zone group containing one zone and one or more Ceph RGW instances where you may load-balance gateway client requests between the instances. 
In a single zone configuration, typically multiple gateway instances point to a single Ceph storage cluster.

In this lab we are going to deploy an advanced configuration that consists of one zone group and two zones, each zone with three Ceph RGW instances. Each zone is backed by its own Ceph Storage Cluster. 
Multiple zones in a zone group provides disaster recovery for the zone group should one of the zones experience a significant failure. **Each zone is active and may receive write operations**.

A logical representation of realm, zone group and zone of our deployment is represented in the following diagram:

<center><img src="scenario3/images/RH-Summit-RGW-Realm.png" border=0/></center>

First lets be sure the RGW services are stopped in all the nodes or both clusters:

```
# cd /root/dc1/ceph-ansible
# for i in a b c; do ansible -b -i inventory -m shell -a "systemctl stop ceph-radosgw@rgw.ceph${i}.service" ceph${i}; done
# cd /root/dc2/ceph-ansible
# for i in 1 2 3 ; do ansible -b -i inventory -m shell -a "systemctl stop ceph-radosgw@rgw.ceph${i}.service" ceph${i}; done
```

> NOTE: All RGW services *SHOULD BE STOPPED* before following this procedure to create realms, zone groups and zones.


Prepare multi-site environment. Define and export variables, here we export all the variables we are going to need during the configuration of the realm, zone group and zones; 
Our master zone is going to be DC1 and the secondary DC2.

```
export REALM="summitlab"
export ZONEGROUP="production"
export MASTER_ZONE="dc1"
export SECONDARY_ZONE="dc2"
export ENDPOINTS_MASTER_ZONE="http://cepha:8080,http://cephb:8080,http://cephc:8080"
export URL_MASTER_ZONE="http://cepha:8080"
export ENDPOINTS_SECONDARY_ZONE="http://ceph1:8080,http://ceph2:8080,http://ceph3:8080"
export URL_SECONDARY_ZONE="http://ceph1:8080"
export SYNC_USER="sync-user"
export ACCESS_KEY="redhat"
export SECRET_KEY="redhat"
```
> WARNING: Shell variables are contained exclusively within the shell in which they were set or defined, if you open a new session or terminal during the duration of scenario 03, you will have to re-export the variables specified in the snippet above.

## Configure Master Zone

Master zone: Execute the following commands in the RGW node of DC1 (cepha).

### Create realm, zone group and zone in Master Zone

A realm contains the multi-site configuration of zone groups and zones, also serves to enforce a globally unique namespace within the realm.

Create the realm:
```
[root@bastion ~]# radosgw-admin --cluster dc1 realm create --rgw-realm=${REALM} --default
{
    "id": "81fb554d-079c-4047-8387-f68d16564cc3",
    "name": "summitlab",
    "current_period": "a188d0d3-cfe9-45e2-97c9-604d9d21221b",
    "epoch": 1
}
```

A realm must have at least one zone group, which will serve as the master zone group for the realm.
Create the zone group with the RGW replication endpoints of the master zone:
```
[root@bastion ~]# radosgw-admin --cluster dc1 zonegroup create --rgw-zonegroup=${ZONEGROUP} --endpoints=${ENDPOINTS_MASTER_ZONE} --rgw-realm=${REALM} --master --default
{
    "id": "00ba3e86-1207-49ba-9df6-cd2a8a07de2a",
    "name": "production",
    "api_name": "production",
    "is_master": "true",
    "endpoints": [
        "http://cepha:8080"
    ],
    "hostnames": [],
    "hostnames_s3website": [],
    "master_zone": "",
    "zones": [],
    "placement_targets": [],
    "default_placement": "",
    "realm_id": "81fb554d-079c-4047-8387-f68d16564cc3"
}
```

Create a master zone for the multi-site configuration by opening a command line interface on a host identified to serve in the master zone group and zone.

Create the zones with the RGW replication endpoints of the master zone(cepha):
```
[root@bastion ~]# radosgw-admin --cluster dc1 zone create --rgw-zonegroup=${ZONEGROUP} --rgw-zone=${MASTER_ZONE} --endpoints=${ENDPOINTS_MASTER_ZONE} --master --default
{
    "id": "6d1a4a77-75bb-45ca-8088-05d6e7d3e223",
    "name": "dc1",
    "domain_root": "dc1.rgw.meta:root",
    "control_pool": "dc1.rgw.control",
    "gc_pool": "dc1.rgw.log:gc",
    "lc_pool": "dc1.rgw.log:lc",
    "log_pool": "dc1.rgw.log",
    "intent_log_pool": "dc1.rgw.log:intent",
    "usage_log_pool": "dc1.rgw.log:usage",
    "reshard_pool": "dc1.rgw.log:reshard",
    "user_keys_pool": "dc1.rgw.meta:users.keys",
    "user_email_pool": "dc1.rgw.meta:users.email",
    "user_swift_pool": "dc1.rgw.meta:users.swift",
    "user_uid_pool": "dc1.rgw.meta:users.uid",
    "system_key": {
        "access_key": "",
        "secret_key": ""
    },
    "placement_pools": [
        {
            "key": "default-placement",
            "val": {
                "index_pool": "dc1.rgw.buckets.index",
                "data_pool": "dc1.rgw.buckets.data",
                "data_extra_pool": "dc1.rgw.buckets.non-ec",
                "index_type": 0,
                "compression": ""
            }
        }
    ],
    "metadata_heap": "",
    "tier_config": [],
    "realm_id": "81fb554d-079c-4047-8387-f68d16564cc3"
}
```

Let's do some checks before we continue into the next step, first lets list our realm, zone group and master zone that we just created with the `radosgw-admin` command.
```
[root@bastion ceph-ansible]# radosgw-admin --cluster dc1 realm list
{
    "default_info": "4596a75e-1663-4940-9e4c-a51554a48b53",
    "realms": [
        "summitlab"
    ]
}

[root@bastion ceph-ansible]# radosgw-admin --cluster dc1 zonegroup list
{
    "default_info": "35712d7d-9582-4dcd-b545-612829a27ad6",
    "zonegroups": [
        "production",
        "default"
    ]
}

[root@bastion ceph-ansible]# radosgw-admin --cluster dc1 zone list
{
    "default_info": "0163e851-3af0-4aa2-b01a-4ad11e4a86bd",
    "zones": [
        "dc1",
        "default"
    ]
}
```

Also let's check our endpoints are configured ok:
```
[root@bastion ~]# radosgw-admin --cluster dc1 zonegroup  get production | grep -A 3 endpoints
    "endpoints": [
        "http://cepha:8080",
        "http://cephb:8080",
        "http://cephc:8080"
--
            "endpoints": [
                "http://cepha:8080",
                "http://cephb:8080",
                "http://cephc:8080"
```

If everything looks ok, we can continue with the next steps.

### Create the sync user in Master Zone and start the RGW service.

At a high level, these are the steps we have to perform now:

1. Create the sync-user.
2. Assign the sync-user to the master zone.
3. Update the period.
4. Start RGW service in DC1 (cepha node)in the master zone nodes.

#### Create the sync-user

Create the sync user. This is a system RGW user that will be used by both clusters to connect to each other so data
can be synced between them.
```
[root@bastion ~]# radosgw-admin --cluster dc1 user create --uid=${SYNC_USER} --display-name="Synchronization User" --access-key=${ACCESS_KEY} --secret=${SECRET_KEY} --system
{
    "user_id": "sync-user",
    "display_name": "Synchronization User",
    "email": "",
    "suspended": 0,
    "max_buckets": 1000,
    "auid": 0,
    "subusers": [],
    "keys": [
        {
            "user": "sync-user",
            "access_key": "redhat",
            "secret_key": "redhat"
        }
    ],
    "swift_keys": [],
    "caps": [],
    "op_mask": "read, write, delete",
    "system": "true",
    "default_placement": "",
    "placement_tags": [],
    "bucket_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "user_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "temp_url_keys": [],
    "type": "rgw"
}
```

#### Assign the sync-user to the master zone

Assign the sync user we created before to the master zone:
```
[root@bastion ~]# radosgw-admin --cluster dc1 zone modify --rgw-zone=${MASTER_ZONE} --access-key=${ACCESS_KEY} --secret=${SECRET_KEY}
{
    "id": "6d1a4a77-75bb-45ca-8088-05d6e7d3e223",
    "name": "dc1",
    "domain_root": "dc1.rgw.meta:root",
    "control_pool": "dc1.rgw.control",
    "gc_pool": "dc1.rgw.log:gc",
    "lc_pool": "dc1.rgw.log:lc",
    "log_pool": "dc1.rgw.log",
    "intent_log_pool": "dc1.rgw.log:intent",
    "usage_log_pool": "dc1.rgw.log:usage",
    "reshard_pool": "dc1.rgw.log:reshard",
    "user_keys_pool": "dc1.rgw.meta:users.keys",
    "user_email_pool": "dc1.rgw.meta:users.email",
    "user_swift_pool": "dc1.rgw.meta:users.swift",
    "user_uid_pool": "dc1.rgw.meta:users.uid",
    "system_key": {
        "access_key": "redhat",
        "secret_key": "redhat"
    },
    "placement_pools": [
        {
            "key": "default-placement",
            "val": {
                "index_pool": "dc1.rgw.buckets.index",
                "data_pool": "dc1.rgw.buckets.data",
                "data_extra_pool": "dc1.rgw.buckets.non-ec",
                "index_type": 0,
                "compression": ""
            }
        }
    ],
    "metadata_heap": "",
    "tier_config": [],
    "realm_id": "81fb554d-079c-4047-8387-f68d16564cc3"
}
```

#### Update the period

Update the period:
```
[root@bastion ~]# radosgw-admin --cluster dc1 period update --commit
{
    "id": "72480644-e86d-4508-990c-ad4440266a3b",
    "epoch": 1,
    "predecessor_uuid": "8d1ee72b-c987-4b16-85d1-7b663d4def60",
    "sync_status": [],
    "period_map": {
        "id": "72480644-e86d-4508-990c-ad4440266a3b",
        "zonegroups": [
            {
                "id": "35712d7d-9582-4dcd-b545-612829a27ad6",
                "name": "production",
                "api_name": "production",
                "is_master": "true",
                "endpoints": [
                    "http://cepha:8080",
                    "http://cephb:8080",
                    "http://cephc:8080"
                ],
                "hostnames": [],
                "hostnames_s3website": [],
                "master_zone": "0163e851-3af0-4aa2-b01a-4ad11e4a86bd",
                "zones": [
                    {
                        "id": "0163e851-3af0-4aa2-b01a-4ad11e4a86bd",
                        "name": "dc1",
                        "endpoints": [
                            "http://cepha:8080",
                            "http://cephb:8080",
                            "http://cephc:8080"
                        ],
                        "log_meta": "false",
                        "log_data": "false",
                        "bucket_index_max_shards": 0,
                        "read_only": "false",
                        "tier_type": "",
                        "sync_from_all": "true",
                        "sync_from": []
                    }
                ],
                "placement_targets": [
                    {
                        "name": "default-placement",
                        "tags": []
                    }
                ],
                "default_placement": "default-placement",
                "realm_id": "4596a75e-1663-4940-9e4c-a51554a48b53"
            }
        ],
        "short_zone_ids": [
            {
                "key": "0163e851-3af0-4aa2-b01a-4ad11e4a86bd",
                "val": 3978111802
            }
        ]
    },
    "master_zonegroup": "35712d7d-9582-4dcd-b545-612829a27ad6",
    "master_zone": "0163e851-3af0-4aa2-b01a-4ad11e4a86bd",
    "period_config": {
        "bucket_quota": {
            "enabled": false,
            "check_on_raw": false,
            "max_size": -1,
            "max_size_kb": 0,
            "max_objects": -1
        },
        "user_quota": {
            "enabled": false,
            "check_on_raw": false,
            "max_size": -1,
            "max_size_kb": 0,
            "max_objects": -1
        }
    },
    "realm_id": "4596a75e-1663-4940-9e4c-a51554a48b53",
    "realm_name": "summitlab",
    "realm_epoch": 2
}
```

### Start RGW service in DC1 (cepha node).

Once we have finished the configuration of the realm, zone group and zone we can start our RGW services in DC1:
```
[root@bastion ceph-ansible]# cd ~/dc1/ceph-ansible/
[root@bastion ceph-ansible]# for i in a b c; do ansible -b -i inventory -m shell -a "systemctl start ceph-radosgw@rgw.ceph${i}.service" ceph${i}; done

cepha | SUCCESS | rc=0 >>

cephb | SUCCESS | rc=0 >>

cephc | SUCCESS | rc=0 >>
```

Lets check that the RGW services are running on the 3 nodes of the cluster:
```
[root@bastion ~]# ceph --cluster dc1 -s | grep -i rgw
    rgw: 3 daemons active
    
[root@bastion ~]# ansible -b -m shell -a "docker ps | grep rgw" cepha,cephb,cephc
cephc | SUCCESS | rc=0 >>
5995d5b99881        10.0.0.10:5000/rhceph/rhceph-3-rhel7:latest   "/entrypoint.sh"    About a minute ago   Up About a minute                       ceph-rgw-cephc

cephb | SUCCESS | rc=0 >>
14c3bbd08ac5        10.0.0.10:5000/rhceph/rhceph-3-rhel7:latest   "/entrypoint.sh"    About a minute ago   Up About a minute                       ceph-rgw-cephb

cepha | SUCCESS | rc=0 >>
88b10f4aabd7        10.0.0.10:5000/rhceph/rhceph-3-rhel7:latest   "/entrypoint.sh"    2 minutes ago       Up 2 minutes                            ceph-rgw-cepha
```

We should now have 3 new DC1 pools that have been created by RGW during the startup of the service:
```
[root@bastion ceph-ansible]# ceph --cluster dc1 osd lspools 
1 .rgw.root,2 dc1.rgw.control,3 dc1.rgw.meta,4 dc1.rgw.log,
```

And also a quick check with curl so we can verify we can access port 8080 provided by the RGW service on each node:
```
[root@bastion ~]# for NODE in a b c; do echo -e "\n" ; curl http://ceph${NODE}:8080; done


<?xml version="1.0" encoding="UTF-8"?><Error><Code>NoSuchBucket</Code><BucketName>cepha</BucketName><RequestId>tx000000000000000000004-005cab7931-4b24e-dc1</RequestId><HostId>4b24e-dc1-production</HostId></Error>

<?xml version="1.0" encoding="UTF-8"?><Error><Code>NoSuchBucket</Code><BucketName>cephb</BucketName><RequestId>tx000000000000000000004-005cab7931-48b05-dc1</RequestId><HostId>48b05-dc1-production</HostId></Error>

<?xml version="1.0" encoding="UTF-8"?><Error><Code>NoSuchBucket</Code><BucketName>cephc</BucketName><RequestId>tx000000000000000000004-005cab7931-48b02-dc1</RequestId><HostId>48b02-dc1-production</HostId></Error>
```

With these basic checks we can move forward and configure our DC2 Ceph cluster as the slave zone in our zone group.

## Configure Secondary Zone(DC2)

Secondary zone: Execute the following commands in the RGW node of DC2 (ceph1)

Pull the realm information from our Master Zone(DC1), here we are using the access-key and the secret from the sync user we created previously:
```
[root@bastion ~]# radosgw-admin --cluster dc2 realm pull --url=${URL_MASTER_ZONE} --access-key=${ACCESS_KEY} --secret=${SECRET_KEY} --rgw-realm=${REALM}
2019-04-19 09:28:25.620757 7fb46137de00  1 error read_lastest_epoch .rgw.root:periods.075aa943-2b7c-4209-80b7-eabafb2f74d0.latest_epoch
2019-04-19 09:28:25.643588 7fb46137de00  1 Set the period's master zonegroup fd0929f8-98e5-4b9e-9493-7b68038f9826 as the default
{
    "id": "ad9b57f0-f988-4c1f-84b5-d8f73bf4698c",
    "name": "summitlab",
    "current_period": "075aa943-2b7c-4209-80b7-eabafb2f74d0",
    "epoch": 2
}
```

Set the realm we just pulled from the Master Zone(Summitlab) as the default one for cluster DC2:
```
[root@bastion ~]# radosgw-admin --cluster dc2 realm default --rgw-realm=${REALM}

```

Pull the period information from the master zone:
```
[root@bastion ~]# radosgw-admin --cluster dc2 period pull --url=${URL_MASTER_ZONE} --access-key=${ACCESS_KEY} --secret=${SECRET_KEY}
2019-04-19 09:28:53.555244 7f23f1f48e00  1 found existing latest_epoch 1 >= given epoch 1, returning r=-17
{
    "id": "075aa943-2b7c-4209-80b7-eabafb2f74d0",
    "epoch": 1,
    "predecessor_uuid": "43eeda2c-f158-4a4c-840f-ec5516c94d19",
    "sync_status": [],
    "period_map": {
        "id": "075aa943-2b7c-4209-80b7-eabafb2f74d0",
        "zonegroups": [
            {
                "id": "fd0929f8-98e5-4b9e-9493-7b68038f9826",
                "name": "production",
                "api_name": "production",
                "is_master": "true",
                "endpoints": [
                    "http://cepha:8080",
                    "http://cephb:8080",
                    "http://cephc:8080"
                ],
                "hostnames": [],
                "hostnames_s3website": [],
                "master_zone": "7c8cfb46-2570-4b57-89f8-b5a4debb8767",
                "zones": [
                    {
                        "id": "7c8cfb46-2570-4b57-89f8-b5a4debb8767",
                        "name": "dc1",
                        "endpoints": [
                            "http://cepha:8080",
                            "http://cephb:8080",
                            "http://cephc:8080"
                        ],
                        "log_meta": "false",
                        "log_data": "false",
                        "bucket_index_max_shards": 0,
                        "read_only": "false",
                        "tier_type": "",
                        "sync_from_all": "true",
                        "sync_from": []
                    }
                ],
                "placement_targets": [
                    {
                        "name": "default-placement",
                        "tags": []
                    }
                ],
                "default_placement": "default-placement",
                "realm_id": "ad9b57f0-f988-4c1f-84b5-d8f73bf4698c"
            }
        ],
        "short_zone_ids": [
            {
                "key": "7c8cfb46-2570-4b57-89f8-b5a4debb8767",
                "val": 222441854
            }
        ]
    },
    "master_zonegroup": "fd0929f8-98e5-4b9e-9493-7b68038f9826",
    "master_zone": "7c8cfb46-2570-4b57-89f8-b5a4debb8767",
    "period_config": {
        "bucket_quota": {
            "enabled": false,
            "check_on_raw": false,
            "max_size": -1,
            "max_size_kb": 0,
            "max_objects": -1
        },
        "user_quota": {
            "enabled": false,
            "check_on_raw": false,
            "max_size": -1,
            "max_size_kb": 0,
            "max_objects": -1
        }
    },
    "realm_id": "ad9b57f0-f988-4c1f-84b5-d8f73bf4698c",
    "realm_name": "summitlab",
    "realm_epoch": 2
}
```

Now that we have the info from the latest period in DC2, let's create a new zone, this zone is for DC2 cluster and will be the secondary zone for our master zone DC1:
```
[root@bastion ~]# radosgw-admin --cluster dc2 zone create --rgw-zonegroup=${ZONEGROUP} --rgw-zone=${SECONDARY_ZONE} --endpoints=${ENDPOINTS_SECONDARY_ZONE} --access-key=${ACCESS_KEY} --secret=${SECRET_KEY}
2019-04-19 09:29:10.843299 7f028ace3e00  0 failed reading obj info from .rgw.root:zone_info.7c8cfb46-2570-4b57-89f8-b5a4debb8767: (2) No such file or directory
2019-04-19 09:29:10.843350 7f028ace3e00  0 WARNING: could not read zone params for zone id=7c8cfb46-2570-4b57-89f8-b5a4debb8767 name=dc1
{
    "id": "bf4a5715-8561-4b19-ba01-a2a7ed7b4668",
    "name": "dc2",
    "domain_root": "dc2.rgw.meta:root",
    "control_pool": "dc2.rgw.control",
    "gc_pool": "dc2.rgw.log:gc",
    "lc_pool": "dc2.rgw.log:lc",
    "log_pool": "dc2.rgw.log",
    "intent_log_pool": "dc2.rgw.log:intent",
    "usage_log_pool": "dc2.rgw.log:usage",
    "reshard_pool": "dc2.rgw.log:reshard",
    "user_keys_pool": "dc2.rgw.meta:users.keys",
    "user_email_pool": "dc2.rgw.meta:users.email",
    "user_swift_pool": "dc2.rgw.meta:users.swift",
    "user_uid_pool": "dc2.rgw.meta:users.uid",
    "system_key": {
        "access_key": "redhat",
        "secret_key": "redhat"
    },
    "placement_pools": [
        {
            "key": "default-placement",
            "val": {
                "index_pool": "dc2.rgw.buckets.index",
                "data_pool": "dc2.rgw.buckets.data",
                "data_extra_pool": "dc2.rgw.buckets.non-ec",
                "index_type": 0,
                "compression": ""
            }
        }
    ],
    "metadata_heap": "",
    "tier_config": [],
    "realm_id": "ad9b57f0-f988-4c1f-84b5-d8f73bf4698c"
}

```

Update the period, we are now updating the period for our multi-site configuration with the information of the new secondary zone we just created, once the period is updated, master zone DC1 will know it has a secondary zone DC2 that needs to be in sync:
```
[root@bastion ~]# radosgw-admin --cluster dc2 period update --commit
2019-04-19 09:29:22.594724 7f9558376e00  1 Cannot find zone id=bf4a5715-8561-4b19-ba01-a2a7ed7b4668 (name=dc2), switching to local zonegroup configuration
Sending period to new master zone 7c8cfb46-2570-4b57-89f8-b5a4debb8767
{
    "id": "075aa943-2b7c-4209-80b7-eabafb2f74d0",
    "epoch": 2,
    "predecessor_uuid": "43eeda2c-f158-4a4c-840f-ec5516c94d19",
    "sync_status": [],
    "period_map": {
        "id": "075aa943-2b7c-4209-80b7-eabafb2f74d0",
        "zonegroups": [
            {
                "id": "fd0929f8-98e5-4b9e-9493-7b68038f9826",
                "name": "production",
                "api_name": "production",
                "is_master": "true",
                "endpoints": [
                    "http://cepha:8080",
                    "http://cephb:8080",
                    "http://cephc:8080"
                ],
                "hostnames": [],
                "hostnames_s3website": [],
                "master_zone": "7c8cfb46-2570-4b57-89f8-b5a4debb8767",
                "zones": [
                    {
                        "id": "7c8cfb46-2570-4b57-89f8-b5a4debb8767",
                        "name": "dc1",
                        "endpoints": [
                            "http://cepha:8080",
                            "http://cephb:8080",
                            "http://cephc:8080"
                        ],
                        "log_meta": "false",
                        "log_data": "true",
                        "bucket_index_max_shards": 0,
                        "read_only": "false",
                        "tier_type": "",
                        "sync_from_all": "true",
                        "sync_from": []
                    },
                    {
                        "id": "bf4a5715-8561-4b19-ba01-a2a7ed7b4668",
                        "name": "dc2",
                        "endpoints": [
                            "http://ceph1:8080",
                            "http://ceph2:8080",
                            "http://ceph3:8080"
                        ],
                        "log_meta": "false",
                        "log_data": "true",
                        "bucket_index_max_shards": 0,
                        "read_only": "false",
                        "tier_type": "",
                        "sync_from_all": "true",
                        "sync_from": []
                    }
                ],
                "placement_targets": [
                    {
                        "name": "default-placement",
                        "tags": []
                    }
                ],
                "default_placement": "default-placement",
                "realm_id": "ad9b57f0-f988-4c1f-84b5-d8f73bf4698c"
            }
        ],
        "short_zone_ids": [
            {
                "key": "7c8cfb46-2570-4b57-89f8-b5a4debb8767",
                "val": 222441854
            },
            {
                "key": "bf4a5715-8561-4b19-ba01-a2a7ed7b4668",
                "val": 1157648815
            }
        ]
    },
    "master_zonegroup": "fd0929f8-98e5-4b9e-9493-7b68038f9826",
    "master_zone": "7c8cfb46-2570-4b57-89f8-b5a4debb8767",
    "period_config": {
        "bucket_quota": {
            "enabled": false,
            "check_on_raw": false,
            "max_size": -1,
            "max_size_kb": 0,
            "max_objects": -1
        },
        "user_quota": {
            "enabled": false,
            "check_on_raw": false,
            "max_size": -1,
            "max_size_kb": 0,
            "max_objects": -1
        }
    },
    "realm_id": "ad9b57f0-f988-4c1f-84b5-d8f73bf4698c",
    "realm_name": "summitlab",
    "realm_epoch": 2
}
```

Start RGW services in the secondary zone nodes:
```
cd ~/dc2/ceph-ansible/
for i in 1 2 3 ; do ansible -b -i inventory -m shell -a "systemctl start ceph-radosgw@rgw.ceph${i}.service" ceph${i}; done
```

Like we did with DC1, let's run a quick check with curl so we can verify we can access port 8080 provided by the RGW service on each node:
```
[root@bastion ~]# for NODE in a b c; do echo -e "\n" ; curl http://ceph${NODE}:8080; done


<?xml version="1.0" encoding="UTF-8"?><Error><Code>NoSuchBucket</Code><BucketName>cepha</BucketName><RequestId>tx000000000000000000004-005cab7931-4b24e-dc1</RequestId><HostId>4b24e-dc1-production</HostId></Error>

<?xml version="1.0" encoding="UTF-8"?><Error><Code>NoSuchBucket</Code><BucketName>cephb</BucketName><RequestId>tx000000000000000000004-005cab7931-48b05-dc1</RequestId><HostId>48b05-dc1-production</HostId></Error>

<?xml version="1.0" encoding="UTF-8"?><Error><Code>NoSuchBucket</Code><BucketName>cephc</BucketName><RequestId>tx000000000000000000004-005cab7931-48b02-dc1</RequestId><HostId>48b02-dc1-production</HostId></Error>
```

Once we have finished the configuration of our second zone, we can check the sync status between zone DC1 and zone DC2:
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
                        data is caught up with source
```

```
[root@bastion ~]# radosgw-admin  --cluster dc2 sync status
          realm 80827d79-3fce-4b55-9e73-8c67ceab4f73 (summitlab)
      zonegroup 88222e12-006a-4cac-a5ab-03925365d817 (production)
           zone ed9f1807-7bc8-48c0-b82f-0fa1511ba47b (dc2)
  metadata sync syncing
                full sync: 0/64 shards
                incremental sync: 64/64 shards
                metadata is caught up with master
      data sync source: 602f21ea-7664-4662-bad8-0c3840bb1d7a (dc1)
                        syncing
                        full sync: 0/128 shards
                        incremental sync: 128/128 shards
                        data is caught up with source
```

## Clean-up RGW installation in both clusters

Lets clean-up the default RGW installation, by default when ever a RGW daemon starts, it will configure and use a default zone and zone group, to avoid confusions it's always better to delete our default zone and zone groups in both clusters.

Once RGW services are working with the new values, delete the default zone group and zones.

First from the master zone we remove the zone default from the zone group default so we can delete it:
```
radosgw-admin --cluster dc1 zonegroup remove --rgw-zonegroup=default --rgw-zone=default
radosgw-admin --cluster dc1 period update --commit
```

Now we can delete the default zone from both clusters:
```
radosgw-admin --cluster dc1 zone delete --rgw-zone=default
radosgw-admin --cluster dc1 period update --commit
radosgw-admin --cluster dc2 zone delete --rgw-zone=default
radosgw-admin --cluster dc2 period update --commit
```

Finally we delete the default zone group:
```
radosgw-admin --cluster dc1 zonegroup delete --rgw-zonegroup=default
radosgw-admin --cluster dc1 period update --commit
radosgw-admin --cluster dc2 zonegroup delete --rgw-zonegroup=default
radosgw-admin --cluster dc2 period update --commit
```

We can check that now the default zone and zone groups don't appear when we list the available zones and zone groups:
```
[root@bastion ceph-ansible]# for i in 1 2 ; do radosgw-admin --cluster dc${i} zone list ; radosgw-admin --cluster dc${i} zonegroup list; done
{
    "default_info": "1341a958-8371-4133-85ec-cc8c7fd23bb3",
    "zones": [
        "dc1"
    ]
}

{
    "default_info": "36ce8c58-4da2-41e6-8be6-e247cd2f27c2",
    "zonegroups": [
        "production"
    ]
}

{
    "default_info": "aaeadbfd-ce91-4efa-a39a-dfed4ee31239",
    "zones": [
        "dc2"
    ]
}

{
    "default_info": "36ce8c58-4da2-41e6-8be6-e247cd2f27c2",
    "zonegroups": [
        "production"
    ]
}

```

## [**Next: Configure a S3 client**](https://likid0.github.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/scenario4/04-Configure_S3_client)

## [**-- HOME --**](https://likid0.github.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
