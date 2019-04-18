# S3 policies: Giving external users access to our buckets

From previous labs, we have two different users:
- summit19
- test-user

In this lab we are going to check how S3 policies work and how we can allow access to our personal buckets to other users.


Using *summit19* user credentials, we are going to create a new bucket

```
[root@bastion ~]# s3cmd -c ~/s3-dc1.cfg mb s3://test-s3-policies
Bucket 's3://test-s3-policies/' created
```

Verify that we can upload new objects to our recently created bucket

```
[root@bastion ~]# s3cmd -c ~/s3-dc1.cfg put /etc/hostname s3://test-s3-policies/test
Bucket 's3://test-s3-policies/' created
```

Using *test-user* credentials, try to list the content of the bucket *test-s3-policies*

```
[root@bastion ~]# s3cmd -c ~/s3-test-user-dc1.cfg ls s3://test-s3-policies
PENDING RESULT (EXPECTED RESULT: 403 Forbidden)
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
				"s3:GetObject"
			],
			"Resource": [
				"arn:aws:s3:::test-s3-policies/*"
			]
		}
	]
}
```

Using *summit19* user credentials, set the new policy to *test-s3-policies* buckets

```
[root@bastion ~]# s3cmd -c ~/s3-dc1.cfg setpolicy policy.json s3://test-s3-policies/test
PENDING RESULT
```

Using *test-user* credentials, try to list the content of *test-s3-policies* buckets

```
[root@bastion ~]# s3cmd -c ~/s3-test-user-dc1.cfg ls s3://test-s3-policies
PENDING RESULT (EXPECTED RESULT: 200 OK)
```

Using *test-user* credentials, try to read the content of the test file

```
[root@bastion ~]# s3cmd -c ~/s3-test-user-dc1.cfg get s3://test-s3-policies/test /tmp/test
PENDING RESULT (EXPECTED RESULT: 200 OK)
[root@bastion ~]# cat /tmp/test
PENDING RESULT
```

Using *test-user* credentials, try to put a new object in *test-s3-policies* bucket

```
[root@bastion ~]# s3cmd -c ~/s3-test-user-dc1.cfg put /etc/GREP_COLORS s3://test-s3-policies/test-user-file
PENDING RESULT (EXPECTED RESULT: 403 Forbidden)
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

Using *summit19* user credentials, set the new policy to *test-s3-policies* buckets

```
[root@bastion ~]# s3cmd -c ~/s3-dc1.cfg setpolicy policy.json s3://test-s3-policies/test
PENDING RESULT
```

Using *test-user* credentials, try to list the content of *test-s3-policies* buckets

```
[root@bastion ~]# s3cmd -c ~/s3-test-user-dc1.cfg ls s3://test-s3-policies
PENDING RESULT (EXPECTED RESULT: 200 OK)
```

Using *test-user* credentials, try to read the content of the test file

```
[root@bastion ~]# s3cmd -c ~/s3-test-user-dc1.cfg get s3://test-s3-policies/test /tmp/test
PENDING RESULT (EXPECTED RESULT: 200 OK)
[root@bastion ~]# cat /tmp/test
PENDING RESULT
```

Using *test-user* credentials, try to put a new object in *test-s3-policies* bucket

```
[root@bastion ~]# s3cmd -c ~/s3-test-user-dc1.cfg put /etc/GREP_COLORS s3://test-s3-policies/test-user-file
PENDING RESULT (EXPECTED RESULT: 200 OK)
```

Using *test-user* credentials, try to delete an object in *test-s3-policies* bucket

```
[root@bastion ~]# s3cmd -c ~/s3-test-user-dc1.cfg rm s3://test-s3-policies/test-user-file
PENDING RESULT (EXPECTED RESULT: 200 OK)
[root@bastion ~]# s3cmd -c ~/s3-test-user-dc1.cfg rm s3://test-s3-policies/test
PENDING RESULT (EXPECTED RESULT: 200 OK)
```

## [**-- HOME --**](https://redhatsummitlabs.gitlab.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
