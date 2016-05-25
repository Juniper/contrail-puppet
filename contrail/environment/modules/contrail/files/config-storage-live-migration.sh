#!/bin/sh

set -x
RETVAL=0
## TODO: change arguments from positional to options
## server-ip is required to download live-migration QCOW2 image.

exit 0

ADMIN_TENANT_ID=`keystone tenant-list |grep " admin" | awk '{print $2}'`
## calculating 15% of total available disk space (in GBs)
RADOS_SPACE=`rados df | grep 'total avail' | awk '{printf $3}'`
NFS_VOLUME_SIZE=$(((${RADOS_SPACE} * 15) / (1024 * 1024 * 100)))
echo $NFS_VOLUME_SIZE
# TODO: this check should more with existing quota instead of 1000
if [ ${NFS_VOLUME_SIZE} -gt 1000 ]
then
  echo "${NFS_VOLUME_SIZE} is more than 1000"
  cinder quota-update --gigabytes=${NFS_VOLUME_SIZE} ${ADMIN_TENANT_ID}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "cinder quota-update failed"
    exit 1
  fi
fi
