# Red Hat Tech Exchange 2019

**Title** : Red Hat Ceph Storage: Building an Object Storage Active/Active Multi-site Solution (**R2037**)

**Date**  : 23/27 Sept 2019

## **Authors/Lab Owners**
* Daniel Dominguez <<ddomingu@redhat.com>>
* Jorge Tudela <<jtudelag@redhat.com>>
* Maurizio Garcia <<maugarci@redhat.com>>
* Daniel Parkes <<dparkes@redhat.com>>

## **Lab Contents**

### **Lab Introduction Topics**

1. [**What is Ceph and what can it do for You?**](/labIntro1/01-Lab-WhatIsCeph.md)
2. [**Ceph Rados Gateway Introduction**](/labIntro2/02-Lab_RGW_Introduction.md)
3. [**Ceph Rados Gateway Multisite introduction**](/labIntro3/03-Lab_RGW_MultiSite_Introduction.md)
4. [**Getting Familiar with our Lab environment**](/labIntro4/04-DC1_ceph_cluster.md)

### **Hands-On Scenarios**

1. [**Install and configure a second ceph cluster DC2**](/scenario1/01-DC2_ceph_cluster_installation.md)
2. [**Configure RadosGW in both clusters**](/scenario2/02-RadosGW_configuration.md)
3. [**Configure RadosGW as an Active/Active Multisite Cluster**](/scenario3/03-RadosGW_Multisite_Configuration.md)
4. [**Configure a S3 client and check the Multisite Deployment**](/scenario4/04-Configure_S3_client.md)
5. [**Configure ceph-metrics on cluster DC2**](/scenario5/05-DC2_cephmetrics_configuration.md)
6. [**Playing with S3 policies**](/scenario6/06-S3_policies.md)


## **Welcome**

First of all, it's my pleasure to welcome you to the Red Hat Summit 2019, here at the Boston Convention and Exhibition Center.


## **Access your Lab Environment**

Every attendee gets her/his own lab environment. The labs have already been deployed, to access your lab you need a unique *Identifier (GUID)* that will be part of the hostnames and URL's you need to access.

### **Get *GUID* and Access Information**

The web browser of your laptop should default to [Lab GUID Grabber](https://www.opentlc.com/gg/gg.cgi?profile=generic_summit). On this web page *select the lab* your attending and enter the *Activation Key* that will be given by the lab instructor.

After submitting your input by clicking *Next* you will see the attendee welcome screen with all the information you need:

* The most important part: Your unique lab *GUID*
* A *link* to the *lab guide*
* The *hostnames / URLs* with your *GUID* for *accessing* your lab
* A *link* to a *status page*

### **Access a host via SSH or Browser**

In most cases the lab instructions will use a string as a placeholder for your *GUID* like *<GUID>*.

* Make sure you know your *GUID*
* Open a terminal session to log in to your host:

```
ssh lab-user@bastion-<GUID>.rhpds.opentlc.com
```

>WARNING: *Replace <GUID> with the GUID assigned to your seat!*

**Example**

If your GUID is *83d4*, do this:
```
ssh lab-user@bastion-83d4.rhpds.opentlc.com
```

>TIP: The user for the bastion will default to `lab-user` and SSH key authentication will be used automatically. If for any reason key authentication is not working and the SSH client is asking for a password, use *r3dh4t1!*

Then become root:
```
[lab-user@bastion ~]$ sudo -i
```

Once in the bastion host, you can jump to any Ceph node using the `cloud-user` user.
```
[lab-user@bastion ~]$ ssh cloud-user@ceph2
```

Once you have been able to connect to the bastion host via SSH, you can start the lab you will need to follow the Lab content index that will take you to a step by step guide of each exercise.

If you have any problems at all during the Lab or have any questions about Red Hat, our RHCS ceph distribution, Rados Gateway, etc, please put your hand-up and a lab moderator will be with you shortly to assist - .....

## [**-- HOME --**](https://likid0.github.io/red-hat-ceph-storage-building-an-object-storage-active-active-multisite-solution/#/)
