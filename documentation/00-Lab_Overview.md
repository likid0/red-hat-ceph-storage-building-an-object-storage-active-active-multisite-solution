<img src="images/redhat.png" style="width: 200px;" border=0/>

<h2>Red Hat Summit, Boston 2019</h2>
**Title** : Red Hat Ceph Storage: Building an Object Storage Active/Active Multi-site Solution (**T168C8**)<br>
**Date**  : 8th May 2019<br><br>

**Authors/Lab Owners**
<ul class="tab">
<li>Daniel Dominguez <<ddomingu@redhat.com>></li>
<li>Jorge Luis Tudela Gonzalez <<jtudelag@redhat.com>></li>
<li>Maurizio Garcia<<maugarci@redhat.com>></li>
<li>Daniel Parkes <<dparkes@redhat.com>></li>
</ul>

<!--BREAK-->

**Lab Contents**

1. **What is Ceph and what can it do?**
2. **Ceph Rados Gateway Introduction**
3. **Ceph Rados Gateway Multisite Solution Introruction**
5. [**Getting Familiar with our Lab environment**](01-DC1_ceph_cluster.md)
6. [**Install and configure a second ceph cluster DC2**](02-DC2_ceph_cluster_installation.md)
7. [**Configure RadosGW in both clusters**](03-RadosGW_configuration.md)
8. [**Configure RadosGW as an Active/Active Multisite Cluster**](04-RadosGW_Multisite_Configuration.md)
9. [**Configure a S3 client and check the Multisite Deployment**](05-Configure_S3_client.md)
10. [**Configure ceph-metrics on cluster DC2**](06-DC2_cephmetrics_configuration.md)


**Welcome**

First of all, it's my pleasure to welcome you to the Red Hat Summit 2019, here at the ...

This hands-on lab aims to get you, the attendees, a bit closer to an open Software Defined Storage solution like Ceph, in this lab we are going to  focus on Object Storage, Rados Gateway ...

Whilst you'll be asked to use and explore some fundamental components within ceph, you won't need to install .....


**Access your Lab Environment**

Every attendee gets her/his own lab environment. The labs have already been deployed, to access your lab you need a unique *Identifier (GUID)* that will be part of the hostnames and URL's you need to access.

**Get *GUID* and Access Information**

The web browser of your laptop should default to ADD LINK TO GRABBER URL. On this web page *select the lab* your attending and enter the *Activation Key* that will be given by the lab instructor.

After submitting your input by clicking *Next* you will see the attendee welcome screen with all the information you need:

* The most important part: Your unique lab *GUID*
* A *link* to the *lab guide*
* The *hostnames / URLs* with your *GUID* for *accessing* your lab
* A *link* to a *status page*

**Access a host via SSH or Browser**

In most cases the lab instructions will use a string as a placeholder for your *GUID* like *<GUID>*.

* Make sure you know your *GUID*
* Open a terminal session to log in to your host:

```
ssh hostname-<GUID>.rhpds.opentlc.com
```

* Or open a browser to access a web UI:

```
https://hostname-<GUID>.rhods.opentlc.com
```

>WARNING: *Replace <GUID> with the GUID assigned to your seat!*

**Example**

If your GUID is *83d4*, do this:
```
ssh hostname-83d4.rhpds.opentlc.com
```

TIP: The user will default to `lab-user` and SSH key authentication will be used automatically. If for any reason key authentication is not working and the SSH client is asking for a password, use *r3dh4t1!*

Then become root:
```
[lab-user@hostname-83d4 ~]$ sudo -i
```

Once you have been able to connect to the bastion host via SSH, you can start the lab you will need to follow the Lab content index that will take you to a step by step guide of each exercise.

If you have any problems at all during the Lab or have any questions about Red Hat, our RHCS ceph distribution, Rados Gateway, etc, please put your hand-up and a lab moderator will be with you shortly to assist - .....
