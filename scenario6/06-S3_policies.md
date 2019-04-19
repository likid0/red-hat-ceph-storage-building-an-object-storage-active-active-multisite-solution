# S3 policies: Giving external users access to our buckets

For this lab, we are going to create two new users:

- user1
- user2

In this lab we are going to check how S3 policies work and how we can allow access to our personal buckets to other users.


Let's create both users, we are going to specify a very simple access key and secret for the user to keep it simple.

```
[root@bastion ~]# radosgw-admin --cluster dc1 user create --uid="user1" --display-name="Redhat Summit User 1" --access-key=user1 --secret=user1
{
    "user_id": "user1",
    "display_name": "Redhat Summit User",
    "email": "",
    "suspended": 0,
    "max_buckets": 1000,
    "auid": 0,
    "subusers": [],
    "keys": [
        {
            "user": "user1",
            "access_key": "user1",
            "secret_key": "user1"
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

[root@bastion ~]# radosgw-admin --cluster dc1 user create --uid="user2" --display-name="Redhat Summit User 2" --access-key=user2 --secret=user2
{
    "user_id": "user2",
    "display_name": "Redhat Summit User",
    "email": "",
    "suspended": 0,
    "max_buckets": 1000,
    "auid": 0,
    "subusers": [],
    "keys": [
        {
            "user": "user2",
            "access_key": "user2",
            "secret_key": "user2"
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

Lets configure the S3 clients with the users we just created, we are going to use the previous config file we had, make a copy of the file and edit the credentials with the ones from user1

```
[root@bastion ~]# cp s3-dc1.cfg s3-dc1-user1.cfg
[root@bastion ~]# cat s3-dc1-user1.cfg | grep -i user1
access_key = user1
secret_key = user1

``` 

We can use sed to create the config file for user2.

```
[root@bastion ~]# sed 's/user1/user2/g' s3-dc1-user1.cfg > s3-dc1-user2.cfg
[root@bastion ~]# cat s3-dc1-user2.cfg | grep -i user2
access_key = user2
secret_key = user2
```


Using *user1* user credentials, we are going to create a new bucket

```
[root@bastion ~]# s3cmd -c ~/s3-dc1-user1.cfg mb s3://test-s3-policies
Bucket 's3://test-s3-policies/' created

```

Verify that we can upload new objects to our recently created bucket

```
[root@bastion ~]# s3cmd -c ~/s3-dc1-user1.cfg put /etc/hostname s3://test-s3-policies/test
upload: '/etc/hostname' -> 's3://test-s3-policies/test'  [1 of 1]
 26 of 26   100% in    0s     2.04 kB/s  done
```

Using *user2* credentials, try to list the content of the bucket *test-s3-policies*

```
[root@bastion ~]# s3cmd -c ~/s3-dc1-user2.cfg ls s3://test-s3-policies
ERROR: Access to bucket 'test-s3-policies' was denied
ERROR: S3 error: 403 (AccessDenied)
```

To allow other users to access one of our buckets, we need to write a new policy in JSON format.

We can specify fine-grain actions. All possible actions are documented in [upstream Ceph documentation](
http://docs.ceph.com/docs/luminous/radosgw/bucketpolicy/)

Create a new file with our bucket policy

```
[root@bastion ~]# vim policy.json
{
	"Version": "2012-10-17",
	"Id": "test-s3-policies",
	"Statement": [{
			"Sid": "bucket-owner-full-permission",
			"Effect": "Allow",
			"Principal": {
				"AWS": [
					"arn:aws:iam:::user/user1"
				]
			},
			"Action": [
				"s3:*"
			],
			"Resource": [
				"arn:aws:s3:::*"
			]
		},
		{
			"Sid": "test-user-list-bucket",
			"Effect": "Allow",
			"Principal": {
				"AWS": [
					"arn:aws:iam:::user/user2"
				]
			},
			"Action": [
				"s3:ListBucket"
			],
			"Resource": [
				"arn:aws:s3:::*"
			]
		},
		{
			"Sid": "test-user-read",
			"Effect": "Allow",
			"Principal": {
				"AWS": [
					"arn:aws:iam:::user/user2"
				]
			},
			"Action": [
				"s3:GetObject"
			],
			"Resource": [
				"arn:aws:s3:::test-s3-policies/*"
			]
		}
	]
}

```

Using *user1* user credentials, set the new policy to *test-s3-policies* buckets

```
[root@bastion ~]# s3cmd -c ~/s3-dc1-user1.cfg setpolicy policy.json s3://test-s3-policies/
[root@bastion ~]# 

```

Using *test-user* credentials, try to list the content of *test-s3-policies* buckets

```
[root@bastion ~]#  s3cmd -c ~/s3-dc1-user2.cfg ls s3://test-s3-policies
2019-04-19 14:57       754   s3://test-s3-policies/test
```

Using *test-user* credentials, try to read the content of the test file

```
[root@bastion ~]#  s3cmd -c ~/s3-dc1-user2.cfg get s3://test-s3-policies/test /tmp/test
download: 's3://test-s3-policies/test' -> '/tmp/test'  [1 of 1]
 754 of 754   100% in    0s   127.57 kB/s  done

```

Using *test-user* credentials, try to put a new object in *test-s3-policies* bucket

```
[root@bastion ~]#  s3cmd -c ~/s3-dc1-user2.cfg put /etc/GREP_COLORS s3://test-s3-policies/test-user-file
upload: '/etc/GREP_COLORS' -> 's3://test-s3-policies/test-user-file'  [1 of 1]
 94 of 94   100% in    0s    13.44 kB/s  done
ERROR: S3 error: 403 (AccessDenied)
```

Modify our current bucket policy and allow *test-user* to write and delete objects in the *test-s3-policies* bucket

```
[root@bastion ~]# vim policy.json
{
	"Version": "2012-10-17",
	"Id": "test-s3-policies",
	"Statement": [{
			"Sid": "bucket-owner-full-permission",
			"Effect": "Allow",
			"Principal": {
				"AWS": [
					"arn:aws:iam:::user/summit19"
				]
			},
			"Action": [
				"s3:*"
			],
			"Resource": [
				"arn:aws:s3:::*"
			]
		},
		{
			"Sid": "test-user-list-bucket",
			"Effect": "Allow",
			"Principal": {
				"AWS": [
					"arn:aws:iam:::user/test-user"
				]
			},
			"Action": [
				"s3:ListBucket"
			],
			"Resource": [
				"arn:aws:s3:::*"
			]
		},
		{
			"Sid": "test-user-read",
			"Effect": "Allow",
			"Principal": {
				"AWS": [
					"arn:aws:iam:::user/test-user"
				]
			},
			"Action": [
				"s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
			],
			"Resource": [
				"arn:aws:s3:::test-s3-policies/*"
			]
		}
	]
}
```

Using *user1* user credentials, set the new policy to *test-s3-policies* buckets

```
[root@bastion ~]# s3cmd -c ~/s3-dc1-user1.cfg setpolicy policy.json s3://test-s3-policies/test
```

Using *user2* credentials, try to list the content of *test-s3-policies* buckets

```
[root@bastion ~]#  s3cmd -c ~/s3-dc1-user2.cfg ls s3://test-s3-policies
2019-04-19 14:57       754   s3://test-s3-policies/test
```


Using *user2* credentials, try to put a new object in *test-s3-policies* bucket

```
[root@bastion ~]#  s3cmd -c ~/s3-dc1-user2.cfg put /etc/GREP_COLORS s3://test-s3-policies/test-user-file
upload: '/etc/GREP_COLORS' -> 's3://test-s3-policies/test-user-file'  [1 of 1]
 94 of 94   100% in    0s     7.51 kB/s  done
```

Using *user2* credentials, try to delete an object in *test-s3-policies* bucket

```
[root@bastion ~]#  s3cmd -c ~/s3-dc1-user2.cfg rm s3://test-s3-policies/test-user-file
delete: 's3://test-s3-policies/test-user-file'
[root@bastion ~]#  s3cmd -c ~/s3-dc1-user2.cfg rm s3://test-s3-policies/test-user-file
delete: 's3://test-s3-policies/test-user-file'
```

## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
