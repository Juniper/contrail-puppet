#!/bin/sh

set -x
RESTART_SERVICES=0
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

