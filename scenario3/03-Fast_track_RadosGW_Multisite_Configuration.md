# Rados Gateway Multisite Configuration

A single zone configuration typically consists of one zone group containing one zone and one or more ceph-radosgw instances where you may load-balance gateway client requests between the instances. In a single zone configuration, typically multiple gateway instances point to a single Ceph storage cluster.

In this lab we are going to deploy an advanced configuration that consists of one zone group and two zones, each zone with one(could be more) ceph-radosgw instances. Each zone is backed by its own Ceph Storage Cluster. Multiple zones in a zone group provides disaster recovery for the zone group should one of the zones experience a significant failure, Each zone is active and may receive write operations.

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
```

A realm must have at least one zone group, which will serve as the master zone group for the realm.
Create the zonegroup with the RGW replication endpoints of the master zone:
```
radosgw-admin --cluster dc1 zonegroup create --rgw-zonegroup=${ZONEGROUP} --endpoints=${ENDPOINTS_MASTER_ZONE} --rgw-realm=${REALM} --master --default
```

Create a master zone for the multi-site configuration by opening a command line interface on a host identified to serve in the master zone group and zone.
Create the zones with the RGW replication endpoints of the master zone(cepha):
```
radosgw-admin --cluster dc1 zone create --rgw-zonegroup=${ZONEGROUP} --rgw-zone=${MASTER_ZONE} --endpoints=${ENDPOINTS_MASTER_ZONE} --master --default
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
```

#### Assign the sync-user to the master zone

Assign the user to the master zone:
```
radosgw-admin --cluster dc1 zone modify --rgw-zone=${MASTER_ZONE} --access-key=${ACCESS_KEY} --secret=${SECRET_KEY}
```

#### Update the period

Update the period:
```
radosgw-admin --cluster dc1 period update --commit
}
```

### Start RGW service in DC1 (cepha node).

Start RGW cluster dc1 service in the master zone nodes.
Start the service in the cepha node:
```
ansible -b -m shell -a "systemctl enable ceph-radosgw@rgw.* --now" cepha
```

We can check with ceph status if the RGW service is running:
```
ceph --cluster dc1 -s | grep rgw
```

And also a quick check with curl so we can verify we can access port 8080 provided by the RGW service:
```
curl http://cepha:8080
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
```

```
for pool in $(rados --cluster dc2 lspools | grep ^default);do ceph --cluster dc2  osd pool delete ${pool} ${pool} --yes-i-really-really-mean-it;done
```

## Create RGW user in DC1

Now that our cluster is ready and we have cleaned up the default  pools, let's test our cluster uploading some objects.

First we need to create a RGW user, we have to save the access and secret key from the output.

```
radosgw-admin --cluster dc1 user create --uid="summit19" --display-name="Redhat Summit User"
```

Lets check that our `summit19` is present in our master zone dc1:

```
radosgw-admin --cluster dc1 user list
```

if we wait for both clusters to sync the metadata we can see that the rgw user is also present on cluster dc2:
```
radosgw-admin --cluster dc2 user list
```

## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
