# Rados Gateway Multisite Configuration

A single zone configuration typically consists of one zone group containing one zone and one or more ceph-radosgw instances where you may load-balance gateway client requests between the instances. In a single zone configuration, typically multiple gateway instances point to a single Ceph storage cluster.

In this lab we are going to deploy an advanced configuration that consists of one zone group and two zones, each zone with three ceph-radosgw instances. Each zone is backed by its own Ceph Storage Cluster. Multiple zones in a zone group provides disaster recovery for the zone group should one of the zones experience a significant failure. Each zone is active and may receive write operations.

A logical representation of realm, zonegroup and zone of our deployment is represented in the following diagram:

<center><img src="scenario3/images/RH-Summit-RGW-Realm.png" border=0/></center>

Prepare multi-site environment. Define and export the following variables:

```
export REALM="summitlab"
export ZONEGROUP="production"
export MASTER_ZONE="dc1"
export SECONDARY_ZONE="dc2"
export ENDPOINTS_MASTER_ZONE="http://cepha:8080"
export URL_MASTER_ZONE="http://cepha:8080"
export ENDPOINTS_SECONDARY_ZONE="http://ceph1:8080"
export URL_SECONDARY_ZONE="http://ceph1:8080"
export SYNC_USER="sync-user"
export ACCESS_KEY="redhat"
export SECRET_KEY="redhat"
```

## Configure Master Zone

Master zone: Execute the following commands in the RGW node of DC1 (ceph1).

### Create realm, zonegroup and zone in Master Zone

A realm contains the multi-site configuration of zone groups and zones and also serves to enforce a globally unique namespace within the realm.
Create the realm:
```
radosgw-admin --cluster dc1 realm create --rgw-realm=${REALM} --default
{
    "id": "81fb554d-079c-4047-8387-f68d16564cc3",
    "name": "summitlab",
    "current_period": "a188d0d3-cfe9-45e2-97c9-604d9d21221b",
    "epoch": 1
}
```

A realm must have at least one zone group, which will serve as the master zone group for the realm.
Create the zonegroup with the RGW replication endpoints of the master zone:
```
radosgw-admin --cluster dc1 zonegroup create --rgw-zonegroup=${ZONEGROUP} --endpoints=${ENDPOINTS_MASTER_ZONE} --rgw-realm=${REALM} --master --default
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
radosgw-admin --cluster dc1 zone create --rgw-zonegroup=${ZONEGROUP} --rgw-zone=${MASTER_ZONE} --endpoints=${ENDPOINTS_MASTER_ZONE} --master --default
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

### Create the sync user in Master Zone and start the RGW service.

At a high level, these are the steps we have to perform now:

1. Create the sync-user.
2. Assign the sync-user to the master zone.
3. Update the period.
4. Start RGW service in DC1 (cepha node)in the master zone nodes.

#### Create the sync-user

Create the sync user. Save the ACCESS_KEY and SECRET_KEY values from this command:
```
radosgw-admin --cluster dc1 user create --uid=${SYNC_USER} --display-name="Synchronization User" --access-key=${ACCESS_KEY} --secret=${SECRET_KEY} --system
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

Assign the user to the master zone:
```
radosgw-admin --cluster dc1 zone modify --rgw-zone=${MASTER_ZONE} --access-key=${ACCESS_KEY} --secret=${SECRET_KEY}
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
radosgw-admin --cluster dc1 period update --commit
{
    "id": "9615afd8-819a-48bf-b309-66e79f874c8f",
    "epoch": 1,
    "predecessor_uuid": "a188d0d3-cfe9-45e2-97c9-604d9d21221b",
    "sync_status": [],
    "period_map": {
        "id": "9615afd8-819a-48bf-b309-66e79f874c8f",
        "zonegroups": [
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
                "master_zone": "6d1a4a77-75bb-45ca-8088-05d6e7d3e223",
                "zones": [
                    {
                        "id": "6d1a4a77-75bb-45ca-8088-05d6e7d3e223",
                        "name": "dc1",
                        "endpoints": [
                            "http://cepha:8080"
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
                "realm_id": "81fb554d-079c-4047-8387-f68d16564cc3"
            }
        ],
        "short_zone_ids": [
            {
                "key": "6d1a4a77-75bb-45ca-8088-05d6e7d3e223",
                "val": 3389843235
            }
        ]
    },
    "master_zonegroup": "00ba3e86-1207-49ba-9df6-cd2a8a07de2a",
    "master_zone": "6d1a4a77-75bb-45ca-8088-05d6e7d3e223",
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
    "realm_id": "81fb554d-079c-4047-8387-f68d16564cc3",
    "realm_name": "summitlab",
    "realm_epoch": 2
}
```

### Start RGW service in DC1 (cepha node).

Start RGW --cluster dc1 service in the master zone nodes.
Start the service in the cepha node:
```
ansible -b -m shell -a "systemctl enable ceph-radosgw@rgw.* --now" cepha
cepha | SUCCESS | rc=0 >>
Created symlink from /etc/systemd/system/multi-user.target.wants/ceph-radosgw@rgw.bastion.service to /etc/systemd/system/ceph-radosgw@.service.
```

We can check with ceph status if the RGW service is running:
```
ceph --cluster dc1 -s | grep rgw
    rgw: 1 daemon active
```

And also a quick check with curl so we can verify we can access port 8080 provided by the RGW service:
```
curl http://cepha:8080
<?xml version="1.0" encoding="UTF-8"?><ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>anonymous</ID><DisplayName></DisplayName></Owner><Buckets></Buckets></ListAllMyBucketsResult>
```

With these basic checks we can move forward and configure our DC2 ceph cluster as the slave zone in our zone-group

## Configure Secondary Zone

Secondary zone: Execute the following commands in the RGW node of DC2 (ceph1)

Pull the realm information:
```
radosgw-admin --cluster dc2 realm pull --url=${URL_MASTER_ZONE} --access-key=${ACCESS_KEY} --secret=${SECRET_KEY} --rgw-realm=${REALM}
```

Set the realm as the default one:
```
radosgw-admin --cluster dc2 realm default --rgw-realm=${REALM}
```

Pull the period information:
```
radosgw-admin --cluster dc2 period pull --url=${URL_MASTER_ZONE} --access-key=${ACCESS_KEY} --secret=${SECRET_KEY}
```

Create the secondary zone:
```
radosgw-admin --cluster dc2 zone create --rgw-zonegroup=${ZONEGROUP} --rgw-zone=${SECONDARY_ZONE} --endpoints=${ENDPOINTS_SECONDARY_ZONE} --access-key=${ACCESS_KEY} --secret=${SECRET_KEY}
```

Update the period:
```
radosgw-admin --cluster dc2 period update --commit
```

Start RGW service in the secondary zone nodes:
```
systemctl enable ceph-radosgw@rgw.$(hostname -s) --now
```

Once we have finished the configuration of our second zone, we can check the sync status between zone dc1 and zone dc2
```
radosgw-admin  --cluster dc1 sync status
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
radosgw-admin  --cluster dc2 sync status
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

Lets clean-up the default RGW installation, by default when ever a RGW daemon starts, it will configure and use a default zone and zonegroup, to avoid confusions it's always better to delete our default zone and zonegroups in both clusters.

Once RGW services are working with the new values, delete default values for zonegroup and zone in the master zone:
```
radosgw-admin --cluster dc1 zonegroup remove --rgw-zonegroup=default --rgw-zone=default
radosgw-admin --cluster dc1 period update --commit
radosgw-admin --cluster dc1 zone delete --rgw-zone=default
radosgw-admin --cluster dc1 period update --commit
radosgw-admin --cluster dc2 zone delete --rgw-zone=default
radosgw-admin --cluster dc2 period update --commit
radosgw-admin --cluster dc1 zonegroup delete --rgw-zonegroup=default
radosgw-admin --cluster dc1 period update --commit
radosgw-admin --cluster dc2 zonegroup delete --rgw-zonegroup=default
radosgw-admin --cluster dc2 period update --commit
```

In both cluster, delete default pools. DISCLAIMER: Data will be unaccessible after performing this operation:

```
for pool in $(rados --cluster dc1 lspools | grep ^default);do ceph --cluster dc1  osd pool delete ${pool} ${pool} --yes-i-really-really-mean-it;done
pool 'default.rgw.control' removed
pool 'default.rgw.meta' removed
pool 'default.rgw.log' removed
```

```
for pool in $(rados --cluster dc2 lspools | grep ^default);do ceph --cluster dc2  osd pool delete ${pool} ${pool} --yes-i-really-really-mean-it;done

pool 'default.rgw.control' does not exist
pool 'default.rgw.meta' does not exist
pool 'default.rgw.log' does not exist
```

## Create RGW user in DC1

Now that our cluster is ready and we have cleaned up the default  pools, let's test our cluster uploading some objects.

First we need to create a RGW user, we have to save the access and secret key from the output.

```
radosgw-admin --cluster dc1 user create --uid="summit19" --display-name="Redhat Summit User"
{
    "user_id": "summit19",
    "display_name": "Redhat Summit User",
    "email": "",
    "suspended": 0,
    "max_buckets": 1000,
    "auid": 0,
    "subusers": [],
    "keys": [
        {
            "user": "summit19",
            "access_key": "ZHFNL7J6CJCZRZ0VSVO5",
            "secret_key": "SJ15woJx8hnAz2mNGV78oUPSC3gliowojbOPf2Tb"
        }
    ],
    "swift_keys": [],
    "caps": [],
    "op_mask": "read, write, delete",
    "default_placement": "",
    "placement_tags": [],
    "bucket_quota": {
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
        "enabled": false,
        "check_on_raw": false,
        "max_size": -1,
        "max_size_kb": 0,
        "max_objects": -1
    },
    "temp_url_keys": [],
    "user_quota": {
    "type": "rgw"
}
```

Lets check that our `summit19` is present in our master zone dc1:

```
radosgw-admin --cluster dc1 user list
[
    "summit19",
    "sync-user"
]
```

if we wait for both clusters to sync the metadata we can see that the rgw user is also present on cluster dc2:
```
radosgw-admin --cluster dc2 user list
[
    "summit19",
    "sync-user"
]
```

## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
