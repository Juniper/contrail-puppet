#!/bin/sh

set -x
RETVAL=0
VM_HOST=0
VM_HOSTNAME=$1
STORAGE_SCOPE=$2
MY_HOSTNAME=`hostname`

if [ ${VM_HOSTNAME} != ${MY_HOSTNAME} ]
then
  VM_HOST=0
else
  VM_HOST=1
fi

echo "I am VM_HOST = ${VM_HOST}"

## for some reason, uid/gid are set back to root:root, so adding check for every time
stat -c '%U:%G'  /var/lib/nova/instances/global
STAT_OUTPUT=`stat -c '%U:%G'  /var/lib/nova/instances/global`
if [ "x${STAT_OUTPUT}" != "xnova:nova" ]
then
  if [ -d /var/lib/nova/instances/global ]
  then
    mkdir -p /var/lib/nova/instances/global
  fi
  chown nova:nova /var/lib/nova/instances/global
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
      echo "chown command failed"
      exit 1
  fi
fi
cat /proc/mounts  | grep -q /var/lib/nova/instances/global
RETVAL=$?
if [ $RETVAL -eq 0 ]
then 
  echo "VM is mounted, not doing anything"
  exit 0
fi


CONFIG_VALUE=`/etc/contrail/contrail_setup_utils/openstack-get-config --get /etc/nova/nova.conf DEFAULT live_migration_flag`
RETVAL=$?
echo $?
echo ${CONFIG_VALUE}
if [ $RETVAL -ne 0 ]
then 
  echo "openstack-get-config failed, configure values "
  openstack-config --set /etc/nova/nova.conf DEFAULT live_migration_flag VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE
  openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_listen 0.0.0.0
  openstack-config --set /etc/nova/nova.conf DEFAULT storage_scope ${STORAGE_SCOPE}
  cat /etc/libvirt/libvirtd.conf | sed s/"#listen_tls = 0"/"listen_tls = 0"/ | sed s/"#listen_tcp = 1"/"listen_tcp = 1"/ | sed s/'#auth_tcp = "sasl"'/'auth_tcp = "none"'/ > /tmp/libvirtd.conf
  cp -f  /tmp/libvirtd.conf  /etc/libvirt/libvirtd.conf
  
  cat /etc/default/libvirt-bin | sed s/"-d"/"-d -l"/ > /tmp/libvirtd.tmp
  cp -f /tmp/libvirtd.tmp /etc/default/libvirt-bin
  service nova-compute restart
  service libvirt-bin restart
  CONFIG_VALUE=`/etc/contrail/contrail_setup_utils/openstack-get-config --get /etc/nova/nova.conf DEFAULT live_migration_flag`
fi

## check config values again for comparision
if [ ! "x${CONFIG_VALUE}" = "xVIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE" ]
then
  echo "live_migration_flag value is not correct"
  openstack-config --set /etc/nova/nova.conf DEFAULT live_migration_flag VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE
  openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_listen 0.0.0.0
  openstack-config --set /etc/nova/nova.conf DEFAULT storage_scope ${STORAGE_SCOPE}
  if [ ${VM_HOST} -eq 1 ]
  then
    openstack-config --set /etc/nova/nova.conf DEFAULT resume_guests_state_on_host_boot True
  fi
  cat /etc/libvirt/libvirtd.conf | sed s/"#listen_tls = 0"/"listen_tls = 0"/ | sed s/"#listen_tcp = 1"/"listen_tcp = 1"/ | sed s/'#auth_tcp = "sasl"'/'auth_tcp = "none"'/ > /tmp/libvirtd.conf
  cp -f  /tmp/libvirtd.conf  /etc/libvirt/libvirtd.conf
  
  cat /etc/default/libvirt-bin | sed s/"-d"/"-d -l"/ > /tmp/libvirtd.tmp
  cp -f /tmp/libvirtd.tmp /etc/default/libvirt-bin
  service nova-compute restart
  service libvirt-bin restart
fi


if [ ${VM_HOST} -eq 1 ]
then
  ifconfig livemnfsvgw
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    vif --create livemnfsvgw --mac 00:01:5e:00:00
    ifconfig livemnfsvgw up
  fi
  grep -q "pre-up vif --create livemnfsvgw --mac 00:01:5e:00:00" /etc/network/interfaces
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    echo \"\" >> /etc/network/interfaces
    echo \"auto livemnfsvgw\" >> /etc/network/interfaces
    echo \"iface livemnfsvgw inet manual\" >> /etc/network/interfaces
    echo \"    pre-up vif --create livemnfsvgw --mac 00:01:5e:00:00\" >> /etc/network/interfaces
    echo \"    pre-up ifconfig livemnfsvgw up\" >> /etc/network/interfaces
  fi

  CONFIG_VALUE=`/etc/contrail/contrail_setup_utils/openstack-get-config --get /etc/contrail/contrail-vrouter-agent.conf GATEWAY-1 ip_blocks`
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] || [ ! "x${CONFIG_VALUE}" = "x192.168.101.0/24" ]
  then
    openstack-config --set /etc/contrail/contrail-vrouter-agent.conf GATEWAY-1 routing_instance default-domain:admin:livemnfs:livemnfs
    openstack-config --set /etc/contrail/contrail-vrouter-agent.conf GATEWAY-1 interface livemnfsvgw
    openstack-config --set /etc/contrail/contrail-vrouter-agent.conf GATEWAY-1 ip_blocks 192.168.101.0/24
    service contrail-vrouter-agent restart
  fi
  
  netstat -nr | grep -q 192.168.101.2
  if [ ${RETVAL} -ne 0 ]
  then
    route add -host 192.168.101.2/32 dev livemnfsvgw
  fi
  grep -q "up route add -host 192.168.101.2/32 dev livemnfsvgw" /etc/network/interfaces
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    echo "up route add -host 192.168.101.2/32 dev livemnfsvgw" >> /etc/network/interfaces
  fi
else 
  netstat -nr | grep -q 192.168.101.2
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    route add 192.168.101.2 dev vhost0
  fi

  grep -q "up route add 192.168.101.2 dev vhost0" /etc/network/interfaces
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    echo "up route add 192.168.101.2 dev vhost0" >> /etc/network/interfaces
  fi
fi


ping -c 5 192.168.101.2
RETVAL=$?
if [ $RETVAL -eq 0 ]
then 
  echo "ping done"
  mount 192.168.101.2:/livemnfsvol /var/lib/nova/instances/global
fi
