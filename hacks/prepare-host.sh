#!/bin/bash

# Install packages
yum install -i httpd  yum-utils createrepo
systemctl enable httpd --now
