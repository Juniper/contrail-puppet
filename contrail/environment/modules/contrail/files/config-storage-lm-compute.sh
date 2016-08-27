#!/bin/sh

set -x
RESTART_SERVICES=0
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
    head -n ${snap_lineno}  ${FILE_NAME}                     > ${TEMP_FILE_NAME}
    echo "  /var/lib/nova/instances/global/_base/** r,"     >> ${TEMP_FILE_NAME}
    echo "  /var/lib/nova/instances/global/snapshots/** r," >> ${TEMP_FILE_NAME}
    tail -n ${tail_lineno}  ${FILE_NAME}     >> ${TEMP_FILE_NAME}
    \mv -f ${TEMP_FILE_NAME} ${FILE_NAME}
    apparmor_parser -r ${FILE_NAME}
  fi
fi

LIBVIRT_QEMU_FILENAME=/etc/apparmor.d/abstractions/libvirt-qemu
LIBVIRT_QEMU_TMP_FILENAME=/tmp/libvirt-qemu
if [ -f ${LIBVIRT_QEMU_FILENAME} ]
then
  grep -n 'deny /tmp/' ${LIBVIRT_QEMU_FILENAME}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    echo "deny /tmp/ entry is not there"
  else
    ## Delete "deny /tmp" line
    ## Add ceph related entries
    ## copy lines after "deny /tmp" back to file

    echo "deny /tmp is not there"
    snap_lineno=`grep -n 'deny /tmp/' ${LIBVIRT_QEMU_FILENAME} | cut -d ':' -f 1`
    tail_lineno=`expr ${snap_lineno} - 1`
    start_lineno=`expr ${snap_lineno} + 1`
    echo "deny /tmp is at ${snap_lineno}"
    head -n ${tail_lineno}  ${LIBVIRT_QEMU_FILENAME}         > ${LIBVIRT_QEMU_TMP_FILENAME}
    head -n ${tail_lineno}  ${LIBVIRT_QEMU_FILENAME}         > ${LIBVIRT_QEMU_TMP_FILENAME}1
    echo "  capability mknod, "     >> ${LIBVIRT_QEMU_TMP_FILENAME}
    echo "  /etc/ceph/* r, "        >> ${LIBVIRT_QEMU_TMP_FILENAME}
    echo "  /etc/qemu-ifup ixr, "   >> ${LIBVIRT_QEMU_TMP_FILENAME}
    echo "  /etc/qemu-ifdown ixr, " >> ${LIBVIRT_QEMU_TMP_FILENAME}
    echo "  owner /tmp/* rw, "      >> ${LIBVIRT_QEMU_TMP_FILENAME}
    echo "  /etc/ceph/* r, "        >> ${LIBVIRT_QEMU_TMP_FILENAME}
    tail -n +${start_lineno}  ${LIBVIRT_QEMU_FILENAME}        >> ${LIBVIRT_QEMU_TMP_FILENAME}
    \mv -f ${LIBVIRT_QEMU_TMP_FILENAME} ${LIBVIRT_QEMU_FILENAME}
  fi
fi

## Get the ip address of nova-host.
## NOTE: we already checked about the ip resolution. so awk must
## NOTE: give correct results
#NOVA_HOST_IP=`host ${VM_HOSTNAME} | awk '{printf $4}'`

## Get the configured value of live_migration_flag. Checking this value will
## help to identify if values has been configured or not. if yes, no need to
## restart daemons. else configured and restart the daemons
## TODO: 1. break the condition into multiple conditions to check for each 
## TODO:    of it.
CONFIG_VALUE=`/etc/contrail/contrail_setup_utils/openstack-get-config --get /etc/nova/nova.conf DEFAULT live_migration_flag`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] || [ ! "x${CONFIG_VALUE}" = "xVIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE" ]
then 
  echo "openstack-get-config failed, configure values "
  RESTART_SERVICES=1
  openstack-config --set /etc/nova/nova.conf DEFAULT live_migration_flag VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE
  cat /etc/libvirt/libvirtd.conf | sed s/"#listen_tls = 0"/"listen_tls = 0"/ | sed s/"#listen_tcp = 1"/"listen_tcp = 1"/ | sed s/'#auth_tcp = "sasl"'/'auth_tcp = "none"'/ > /tmp/libvirtd.conf
  cp -f  /tmp/libvirtd.conf  /etc/libvirt/libvirtd.conf
  cat /etc/default/libvirt-bin | sed s/"-d"/"-d -l"/ > /tmp/libvirtd.tmp
  cp -f /tmp/libvirtd.tmp /etc/default/libvirt-bin

  cat /etc/init/libvirt-bin.conf | sed s/"-d"/"-d -l"/ > /tmp/libvirtd.conf
  cp -f /tmp/libvirtd.conf /etc/init/libvirt-bin.conf
  service libvirt-bin restart
fi


CONFIG_VALUE=`/etc/contrail/contrail_setup_utils/openstack-get-config --get /etc/nova/nova.conf DEFAULT vncserver_listen`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] || [ ! "x${CONFIG_VALUE}" = "x0.0.0.0" ]
then 
  openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_listen 0.0.0.0
  RESTART_SERVICES=1
fi

if [ ${RESTART_SERVICES} -eq 1 ]
then
  service nova-compute restart
  service libvirt-bin restart
fi

