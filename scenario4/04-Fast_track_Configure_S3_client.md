# Configure S3 Client

We are now going to configure and S3 client so we can upload objects to our rgw cluster, for this lab we are going to be using a cli tool called s3cmd, s3cmd is already pre-installed on the bastion host:

```
[root@bastion ~]# yum list installed | grep -i s3cmd
```

Lets run the s3cmd command with the configure parameter so we can do a bootstrap config of our s3 client, we are going to first create the configuration for the dc1 zone:

Please fill in the requested data by the application, we use the Access Key and the Secret key from the summit19 user that we created previously, and use cepha:8080 as the S3 endpoint:

Here is and example:

Remember, s3cmd is installed in the bastion host:
```
s3cmd --configure

Enter new values or accept defaults in brackets with Enter.
Refer to user manual for detailed description of all options.

Access key and Secret key are your identifiers for Amazon S3. Leave them empty for using the env variables.
Access Key: ZHFNL7J6CJCZRZ0VSVO5
Secret Key: SJ15woJx8hnAz2mNGV78oUPSC3gliowojbOPf2Tb
Default Region [US]: US

Use "s3.amazonaws.com" for S3 Endpoint and not modify it to the target Amazon S3.
S3 Endpoint [s3.amazonaws.com]: cepha:8080                    

Use "%(bucket)s.s3.amazonaws.com" to the target Amazon S3. "%(bucket)s" and "%(location)s" vars can be used
if the target S3 system supports dns based buckets.
DNS-style bucket+hostname:port template for accessing a bucket [%(bucket)s.s3.amazonaws.com]: cepha:8080

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
  S3 Endpoint: cepha:8080
  DNS-style bucket+hostname:port template for accessing a bucket: cepha:8080
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
mv /root/.s3cfg /root/s3-dc1.cfg
```  

## Create a bucket

Let's create a first bucket using the `s3cmd mb` command, because are not using the default location for the config file of /root/.s3cfg. we need to specify with `-c ~/s3-dc1.cfg` the location of our s3cmd config:

```
s3cmd -c ~/s3-dc1.cfg mb s3://my-first-bucket
```

```
s3cmd -c ~/s3-dc1.cfg ls
```

## Upload an object

Let's upload a file, we are going to use the s3cmd RPM as an example:


```
cd /root
ls
anaconda-ks.cfg  ansible  ceph-ansible-keys  dc1  dc2  original-ks.cfg  red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution  s3cmd-2.0.2-1.el7.noarch.rpm  sync-repos.sh
```

```
s3cmd -c ~/s3-dc1.cfg put s3cmd-2.0.2-1.el7.noarch.rpm s3://my-first-bucket/
```

With `s3cmd la` we can check all the objects in the bucket

```
s3cmd -c ~/s3-dc1.cfg la
```

And with the `s3cmd du` option we can see the disk used by each object:
```
s3cmd -c ~/s3-dc1.cfg du
```

## Check multisite replication

If we run the sync status command after running a put of a large object we would be able to see the secondary cluster doing a sync to keep up with the master

From the bastion:
```
radosgw-admin  --cluster dc2 sync status
```

We can also check that the replication is working by connecting to the second zone dc2 and checking that the bucket and the file we uploaded are present on DC2.

From the bastion:
```
radosgw-admin --cluster dc2 bucket list
```

Our bucket has been created lets take a look at the objects inside the DC2 data pool:
```
rados --cluster dc2  -p dc2.rgw.buckets.data ls
```

## Check active/active multisite replication

As we explained in the introduction RGW can be use as an active/active object storage Multisite solution, lets double check we can also put objects into our second zone DC2.

First we need to create a config file that is pointing to the endpoints of DC(ceph1:8080), we are going to use sed to create a new file from our current DC1 s3cmd configuration file, we only need to replace the endpoint from cepha to ceph1,there is no need to use a different user, all the metadata, including users is replicated between both sites.
```
sed 's/cepha/ceph1/g' /root/s3-dc1.cfg > /root/s3-dc2.cfg
s3cmd -c ~/s3-dc2.cfg  ls
```

We can create a bucket in dc2 and store a file:
```
s3cmd -c ~/s3-dc2.cfg  mb  s3://my-second-bucket
s3cmd -c ~/s3-dc2.cfg  put /var/log/messages  s3://my-second-bucket
 ```

The file is also accessible from zone DC1, our active/active multisite cluster is working without issues.
 ```
s3cmd -c ~/s3-dc1.cfg  ls  s3://my-second-bucket
```

## [**-- HOME --**](https://likid0.github.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
