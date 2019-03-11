#!/bin/bash

# Script to sync repositories.

BASEDIR="/var/www/repos"
REPOS="rhel-7-server-rhceph-3-tools-rpms rhel-7-server-extras-rpms rhel-7-server-rpms"

mkdir -p "${BASEDIR}"

for repo in $REPOS;
do
  echo "$repo"

  echo "Starting to sync $repo " | tee -a sync-repos.log
  reposync --gpgcheck -l -n --repoid="${repo}" --download_path="${BASEDIR}" --downloadcomps --download-metadata | tee -a sync-repos.log
  echo "Finished to sync $repo " | tee -a sync-repos.log

  echo "Creating $repo " | tee -a sync-repos.log
  createrepo "${BASEDIR}/${repo}" | tee -a sync-repos.log
  echo "Finished to sync $repo " | tee -a sync-repos.log

done

echo "Restore SELinux context $BASEDIR " | tee -a sync-repos.log
restorecon -R /var/www/repos/
echo "Give recursive permissions to apache user for $BASEDIR" | tee -a sync-repos.log
chown -R apache:apache /var/www/repos/
