# Ceph Rados Gateway Introduction

RADOS Gateway (RGW) is an object storage interface built on top of librados to provide applications with a RESTful gateway to RADOS clusters. 

The RADOS Gateway supports two interfaces:

1. S3-compatible: Provides block storage functionality with an interface that is compatible with a large subset of the Amazon S3 RESTful API.
2. Swift-compatible: Provides block storage functionality with an interface that is compatible with a large subset of the OpenStack Swift API.

RADOS Gateway is a FastCGI module for interacting with librados. Since it provides interfaces compatible with OpenStack Swift and Amazon S3, RADOS Gateway has its own user management. RADOS Gateway can store data in the same RADOS cluster used to store data from Ceph FS clients or RADOS block devices. The S3 and Swift APIs share a common namespace, so you may write data with one API and retrieve it with the other.

<center><img src="labIntro2/images/ceph-rgw-arq.jpg" style="width:400px;" border=0/></center>


## Resources

* [Ceph RGW docs](http://docs.ceph.com/docs/bobtail/radosgw/)

## [**-- HOME --**](https://likid0.github.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)