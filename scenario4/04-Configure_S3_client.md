Now that our Multi-Site RGW cluster is configured, let's test everything is working like expected by configuring a client to upload some objects.


## Create RGW user in DC1


First we need to create a RGW user, we have to save the access and secret key from the output.

> NOTE: Save the access_key and secret_key You will need them for the next exercise

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

Lets check that our user `summit19` is present in our master zone dc1:

```
radosgw-admin --cluster dc1 user list
[
    "summit19",
    "sync-user"
]
```

if we wait for both clusters to sync the metadata we can see that the rgw user `summit19` is also present on cluster dc2:

```
radosgw-admin --cluster dc2 user list
[
    "summit19",
    "sync-user"
]
```


# Starting the Haproxy LoadBalancers.

In the lab Introduction we mentioned that we had 1 load balancer for each site, this HAproxy loadbalancer will take care of distributing the incoming S3 client requests among the 3 RGW intances we have in each DC. 


<img src="labIntro4/images/lab_description.jpg" height="220"/>


Let's quickly check the configuration of each HAproxy, we have a frontend ip binded this is the IP the clients use to connect, and then our backend with the IPs of the 3 RGW instances we have in DC1.
the frontend IP *10.0.0.100* resolves to *s3.dc1.summit.lab*, this is the name we will use to configure our s3 client in DC1

```
[root@bastion ~]# ssh cloud-user@lbdc1 cat /etc/haproxy/haproxy.cfg | tail
Warning: Permanently added 'lbdc1,10.0.0.100' (ECDSA) to the list of known hosts.
frontend ceph_front
    bind 10.0.0.100:80
    default_backend ceph_back


backend ceph_back
    balance source
    server cepha 10.0.0.11:8080 check
    server cephb 10.0.0.12:8080 check
    server cephc 10.0.0.13:8080 check
```

Here is the same config with the IPs of DC2. The frontend IP *172.16.0.100* resolves to *s3.dc2.summit.lab*

```
[root@bastion ~]# ssh cloud-user@lbdc2 cat /etc/haproxy/haproxy.cfg | tail
Warning: Permanently added 'lbdc2,172.16.0.100' (ECDSA) to the list of known hosts.
frontend ceph_front
    bind 172.16.0.100:80
    default_backend ceph_back


backend ceph_back
    balance source
    server ceph1 172.16.0.11:8080 check
    server ceph2 172.16.0.12:8080 check
    server ceph3 172.16.0.13:8080 check
```

We have to start the haproxy service on both nodes lbdc1 and lbdc2

```
[root@bastion ~]# ansible -b -a "systemctl restart haproxy"  lbdc*
lbdc1 | SUCCESS | rc=0 >>


lbdc2 | SUCCESS | rc=0 >>


[root@bastion ~]# ansible -b -a "systemctl status haproxy"  lbdc*
lbdc2 | SUCCESS | rc=0 >>
● haproxy.service - HAProxy Load Balancer
   Loaded: loaded (/usr/lib/systemd/system/haproxy.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2019-04-18 10:42:51 EDT; 9s ago
 Main PID: 3527 (haproxy-systemd)
   CGroup: /system.slice/haproxy.service
           ├─3527 /usr/sbin/haproxy-systemd-wrapper -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid
           ├─3528 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
           └─3529 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds

Apr 18 10:42:51 lbdc2.rhpds.opentlc.com systemd[1]: Stopped HAProxy Load Balancer.
Apr 18 10:42:51 lbdc2.rhpds.opentlc.com systemd[1]: Started HAProxy Load Balancer.
Apr 18 10:42:51 lbdc2.rhpds.opentlc.com haproxy-systemd-wrapper[3527]: haproxy-systemd-wrapper: executing /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
Apr 18 10:42:51 lbdc2.rhpds.opentlc.com haproxy-systemd-wrapper[3527]: [WARNING] 107/104251 (3528) : config : log format ignored for frontend 'ceph_front' since it has no log address.

lbdc1 | SUCCESS | rc=0 >>
● haproxy.service - HAProxy Load Balancer
   Loaded: loaded (/usr/lib/systemd/system/haproxy.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2019-04-18 10:42:51 EDT; 9s ago
 Main PID: 3637 (haproxy-systemd)
   CGroup: /system.slice/haproxy.service
           ├─3637 /usr/sbin/haproxy-systemd-wrapper -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid
           ├─3639 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
           └─3641 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds

Apr 18 10:42:51 lbdc1.rhpds.opentlc.com systemd[1]: Stopped HAProxy Load Balancer.
Apr 18 10:42:51 lbdc1.rhpds.opentlc.com systemd[1]: Started HAProxy Load Balancer.
Apr 18 10:42:51 lbdc1.rhpds.opentlc.com haproxy-systemd-wrapper[3637]: haproxy-systemd-wrapper: executing /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
Apr 18 10:42:51 lbdc1.rhpds.opentlc.com haproxy-systemd-wrapper[3637]: [WARNING] 107/104251 (3639) : config : log format ignored for frontend 'ceph_front' since it has no log address.

```



# Configure S3 Client


We are now going to configure and S3 client so we can upload objects to our rgw cluster, for this lab we are going to be using a cli tool called s3cmd, s3cmd is already pre-installed on the bastion host:

```
[root@bastion ~]# yum list installed | grep -i s3cmd
s3cmd.noarch                  2.0.2-1.el7             installed
```

Lets run the s3cmd command with the configure parameter so we can do a bootstrap config of our s3 client, we are going to first create the configuration for the dc1 zone:

Please fill in the requested data by the application, we use the Access Key and the Secret key from the *summit19* user that we created previously, and use *s3.dc1.summit.lab* as the *S3 endpoint*:

Here is and example:

Remember, s3cmd is installed in the bastion host:
```
[root@bastion ~]# s3cmd --configure

Enter new values or accept defaults in brackets with Enter.
Refer to user manual for detailed description of all options.

Access key and Secret key are your identifiers for Amazon S3. Leave them empty for using the env variables.
Access Key: ZHFNL7J6CJCZRZ0VSVO5
Secret Key: SJ15woJx8hnAz2mNGV78oUPSC3gliowojbOPf2Tb
Default Region [US]: US

Use "s3.amazonaws.com" for S3 Endpoint and not modify it to the target Amazon S3.
S3 Endpoint [s3.amazonaws.com]: s3.dc1.summit.lab                    

Use "%(bucket)s.s3.amazonaws.com" to the target Amazon S3. "%(bucket)s" and "%(location)s" vars can be used
if the target S3 system supports dns based buckets.
DNS-style bucket+hostname:port template for accessing a bucket [%(bucket)s.s3.amazonaws.com]: s3.dc1.summit.lab

Encryption password is used to protect your files from reading
by unauthorized persons while in transfer to S3
Encryption password:
Path to GPG program [/bin/gpg]: /usr/bin/gpg

When using secure HTTPS protocol all communication with Amazon S3
servers is protected from 3rd party eavesdropping. This method is
slower than plain HTTP, and can only be proxied with Python 2.7 or newer
Use HTTPS protocol [Yes]: No

On some networks all internet access must go through a HTTP proxy.
Try setting it here if you can't connect to S3 directly
HTTP Proxy server name:

New settings:
  Access Key: ZHFNL7J6CJCZRZ0VSVO5
  Secret Key: SJ15woJx8hnAz2mNGV78oUPSC3gliowojbOPf2Tb
  Default Region: US
  S3 Endpoint: s3.dc1.summit.lab
  DNS-style bucket+hostname:port template for accessing a bucket: s3.dc1.summit.lab
  Encryption password:
  Path to GPG program: /usr/bin/gpg
  Use HTTPS protocol: False
  HTTP Proxy server name:
  HTTP Proxy server port: 0

Test access with supplied credentials? [Y/n] Y
Please wait, attempting to list all buckets...
Success. Your access key and secret key worked fine :-)

Now verifying that encryption works...
Not configured. Never mind.

Save settings? [y/N] y
Configuration saved to '/root/.s3cfg'
```

As you can see the configuration for the client has been saved to the following path /root/.s3cfg , lets change the name of the config file to /root/s3-dc1.cfg

```
[root@bastion ~]# mv /root/.s3cfg /root/s3-dc1.cfg
```  

## Create a bucket

Let's create a first bucket using the `s3cmd mb` command, because are not using the default location for the config file of /root/.s3cfg. we need to specify with `-c ~/s3-dc1.cfg` the location of our s3cmd config:

```
[root@bastion ~]# s3cmd -c ~/s3-dc1.cfg mb s3://my-first-bucket
Bucket 's3://my-first-bucket/' created
```

```
[root@bastion ~]# s3cmd -c ~/s3-dc1.cfg ls
2019-03-24 17:49  s3://my-first-bucket
```

## Upload an object

Let's upload a file, we are going to use the s3cmd RPM as an example:

```
[root@bastion ~]# ls
anaconda-ks.cfg  ansible  ceph-ansible-keys  dc1  dc2  original-ks.cfg  red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution  s3cmd-2.0.2-1.el7.noarch.rpm  sync-repos.sh
```

```
[root@bastion ~]# s3cmd -c ~/s3-dc1.cfg put s3cmd-2.0.2-1.el7.noarch.rpm s3://my-first-bucket/

upload: 's3cmd-2.0.2-1.el7.noarch.rpm' -> 's3://my-first-bucket/s3cmd-2.0.2-1.el7.noarch.rpm'  [1 of 1]
 194693 of 194693   100% in    2s    85.00 kB/s  done
```

With `s3cmd la` we can check all the objects in the bucket

```
[root@bastion ~]# s3cmd -c ~/s3-dc1.cfg la
2019-03-24 17:52    194693   s3://my-first-bucket/s3cmd-2.0.2-1.el7.noarch.rpm
```

And with the `s3cmd du` option we can see the disk used by each object:
```
[root@bastion ~]# s3cmd -c ~/s3-dc1.cfg du
194693   1 objects s3://my-first-bucket/
--------
194693   Total
```

## Check multisite replication

If we run the sync status command after running a put of a large object we would be able to see the secondary cluster doing a sync to keep up with the master.
The sync status parameter that is provided by the radosgw-admin CLI gives us an output that is divided in 2 SYNC sections metadata(users,acls,etc) and data(the actual data objects).

From the bastion:
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
                        1 shards are recovering
                        recovering shards: [22]

```

We can also check that the replication is working by connecting to the second zone dc2 and checking that the bucket and the file we uploaded are present on DC2.

From the bastion:
```
[root@bastion ~]# radosgw-admin --cluster dc2 bucket list
[
    "my-first-bucket"
]
```

Our bucket has been created lets take a look using the rados command at the objects inside the DC2 data pool:
```
[root@bastion ~]# rados --cluster dc2  -p dc2.rgw.buckets.data ls
602f21ea-7664-4662-bad8-0c3840bb1d7a.314154.1_s3cmd-2.0.2-1.el7.noarch.rpm
```

## Check active/active multisite replication

As we explained in the introduction RGW can be use as an active/active object storage Multisite solution, lets double check we can also put objects into our second zone DC2.

First we need to create a config file that is pointing to the endpoints of DC2 (s3.dc2.summit.lab), we are going to use sed to create a new file from our current DC1 s3cmd configuration file, we only need to replace the endpoint from cepha to ceph1,there is no need to use a different user, all the metadata, including users is replicated between both sites.
```
[root@bastion ~]# sed 's/s3.dc1.summit.lab/s3.dc2.summit.lab/g' /root/s3-dc1.cfg > /root/s3-dc2.cfg
[root@bastion ~]# s3cmd -c ~/s3-dc2.cfg  ls
2019-03-24 17:49  s3://my-first-bucket
```

We can create a bucket in dc2 and store a file:
```
[root@bastion ~]# s3cmd -c ~/s3-dc2.cfg  mb  s3://my-second-bucket
Bucket 's3://my-second-bucket/' created

[root@bastion ~]# s3cmd -c ~/s3-dc2.cfg  put /var/log/messages  s3://my-second-bucket
upload: '/var/log/messages' -> 's3://my-second-bucket/messages'  [1 of 1]
 181085 of 181085   100% in    0s    10.22 MB/s  done
 ```

The file is also accessible from zone DC1, our active/active multisite cluster is working without issues.
 ```
[root@bastion ~]# s3cmd -c ~/s3-dc1.cfg  ls  s3://my-second-bucket
2019-03-25 08:20    181085   s3://my-second-bucket/messages
```

Another quick example we we create a file upload it to DC2 and download it from DC1:

```
[root@bastion ~]# echo "File Uploaded to DC2" > DC2-file.txt
[root@bastion ~]#  s3cmd -c ~/s3-dc2.cfg  put DC2-file.txt s3://my-second-bucket
upload: 'DC2-file.txt' -> 's3://my-second-bucket/DC2-file.txt'  [1 of 1]
 21 of 21   100% in    0s  1719.62 B/s  done
[root@bastion ~]# rm DC2-file.txt 
rm: remove regular file ‘DC2-file.txt’? y
[root@bastion ~]# s3cmd -c ~/s3-dc1.cfg get s3://my-second-bucket/DC2-file.txt
download: 's3://my-second-bucket/DC2-file.txt' -> './DC2-file.txt'  [1 of 1]
 21 of 21   100% in    0s     2.90 kB/s  done
[root@bastion ~]# cat DC2-file.txt 
File Uploaded to DC2

```


https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/scenario5/05-DC2_cephmetrics_configuration

## [**Next: Configure ceph-metrics on DC2**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/scenario5/05-DC2_cephmetrics_configuration)

## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
