#!/bin/sh

set -x
RETVAL=0

## TODO: change arguments from positional to options
## server-ip is required to download live-migration QCOW2 image.
FILE_NAME=/etc/apparmor.d/usr.lib.libvirt.virt-aa-helper
TEMP_FILE_NAME=/tmp/usr.lib.libvirt.virt-aa-helper

## NOTE: ANY CHANGES FOR FOLLOWING CODE SHOULD BE DONE IN 
## NOTE: config-storage-lm-compute.sh AS WELL.
## NOTE: THIS IS TEMP FIX, AS FILE NEEDS TO BE RE-WRITTEN

if [ -f ${FILE_NAME} ]
then
  grep -n "instances/global" ${FILE_NAME}
  RETVAL=$?
  if [ ${RETVAL} -eq 0 ]
  then
    echo "instance/global entry is there"
  else
    ##copy lines after instances/snapshots
    echo "instances/global is not there"
    snap_lineno=`grep -n "instances/snapshots" ${FILE_NAME} | cut -d ':' -f 1`
    tail_lineno=`expr ${snap_lineno} + 1`
    echo "instances/snapshots is at ${snap_lineno}"
    head -n ${snap_lineno}  ${FILE_NAME} > ${TEMP_FILE_NAME}
    echo "  /var/lib/nova/instances/global/_base/** r," >> ${TEMP_FILE_NAME}
    echo "  /var/lib/nova/instances/global/snapshots/** r," >> ${TEMP_FILE_NAME}
    tail -n ${tail_lineno}  ${FILE_NAME}     >> ${TEMP_FILE_NAME}
    \mv -f ${TEMP_FILE_NAME} ${FILE_NAME}
    apparmor_parser -r ${FILE_NAME}
  fi
fi
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
