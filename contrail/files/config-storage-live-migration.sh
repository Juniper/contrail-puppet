#!/bin/sh

set -x
RETVAL=0
SERVER_IP=$1
NOVA_HOST=$2
NOVA_HOST_IP=`host cmbu-cl73 | awk '{printf $4}'`
RETVAL=$?
if [ ${RETVAL} -ne 0 ]
then
  echo "host resolution failed"
  exit 1
fi


nova_uid=`id -u nova`
dnsmasq_uid=`id -u libvirt-dnsmasq`
qemu_uid=`id -u libvirt-qemu`
nova_gid=`getent group nova | awk -F: '{printf $3}'`
kvm_gid=`getent group kvm| awk -F: '{printf $3}'`
virtd_gid=`getent group libvirtd| awk -F: '{printf $3}'`

cat > /tmp/data.txt << EOF
# data.txt info that has to be passed to nova boot - This will enable the auto configure of the VM.
# The following is sample data.txt
# The UID/GID for nova/libvirt/kvm should be taken from one of the
# compute nodes.  
#NFS VM configuration
#ver 1.0
[DEFAULT]
auto_configure_nfs_services=1
[PASSWD_ENTRIES]
nova=${nova_uid}
libvirt-qemu=${qemu_uid}
libvirt-dnsmasq=${dnsmasq_uid}
[GROUP_ENTRIES]
nova=${nova_gid}
kvm=${kvm_gid}
libvirtd=${virtd_gid}
#end of file
EOF

. /etc/contrail/openstackrc
NUM_IMAGE_LIVEMNFS=`nova image-list | grep livemnfs | wc -l`

if [ ${NUM_IMAGE_LIVEMNFS} -eq 1 ]
then
  DOWNLOAD_REQD=0
elif [ ${NUM_IMAGE_LIVEMNFS} -gt 1 ]
then
  DOWNLOAD_REQD=0
else
  DOWNLOAD_REQD=1
fi


if [ ${DOWNLOAD_REQD} -eq 1 ]
then
  #if [ -f /tmp/livemnfs.qcow2.gz ]
  #then
    #MD5SUM=`md5sum /tmp/livemnfs.qcow2.gz| awk '{printf $1}'`
    #wget -q http://${SERVER_IP}/contrail/images/livemnfs.qcow2.gz.md5sum -O /tmp/livemnfs.qcow2.gz.md5sum
    #RETVAL=$?
    #if [ ${RETVAL} -ne 0 ]
    #then
      #echo "wget failed"
    #exit 1
    #fi
    #MD5SUM_LATEST=`cat /tmp/livemnfs.qcow2.gz.md5sum  |  awk '{print $1}'`
    #if [ "x${MD5SUM}" = "x${MD5SUM_LATEST}" ]
    #then
      #echo "MD5 same, no changes in FILE"
      #DOWNLOAD_REQD=0
    #else
      #echo "MD5SUM diff : existing ${MD5SUM}, new: ${MD5SUM_LATEST}"
      #DOWNLOAD_REQD=1
    #fi
  #fi
  wget -q http://${SERVER_IP}/contrail/images/livemnfs.qcow2.gz -O /tmp/livemnfs.qcow2.gz
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    echo "wget failed"
    exit 1
  fi
  if [ -f /tmp/livemnfs.qcow2 ]
  then
    unlink /tmp/livemnfs.qcow2
  fi
  gunzip /tmp/livemnfs.qcow2.gz
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "gunzip failed"
    exit 1
  fi
  glance image-create --name livemnfs --disk-format qcow2 --container-format ovf --file /tmp/livemnfs.qcow2 --is-public True
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "Glance image create failed"
    exit 1
  fi
fi

LIVE_MIGRATE_NETWORK_NUM=`neutron net-list | grep livemnfs | wc -l `
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "neutron net-list failed"
  exit 1
fi

LIVE_MIGRATE_NETWORK=`neutron net-list | grep livemnfs | awk '{ print $2 }'`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "neutron net-list failed"
  exit 1
fi

if [ ${LIVE_MIGRATE_NETWORK_NUM} -gt 1 ]
then
  echo "more than 1 livemnfs networks"
  exit 1
fi

echo "LM netowrk ${LIVE_MIGRATE_NETWORK} ${LIVE_MIGRATE_NETWORK_NUM}"
if [ -z ${LIVE_MIGRATE_NETWORK} ]
then
  neutron net-create livemnfs
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "neutron net-create failed"
    exit 1
  fi
fi

LIVE_MIGRATE_SUBNET=`neutron subnet-list | grep livemnfs | awk '{ print $2 }'`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "neutron subnet-list failed"
  exit 1
fi

echo "subnet ${LIVE_MIGRATE_SUBNET}"
if [ -z ${LIVE_MIGRATE_SUBNET} ]
then
  neutron subnet-create --name livemnfs livemnfs 192.168.101.0/24
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "neutron subnet-create failed"
    exit 1
  fi
fi

nova-manage host list | grep -w ${NOVA_HOST} | awk '{print $2}' | grep -q nova
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "nova-manage host list doesn't have host/nova"
  exit 1
fi


LM_IMAGE_NUM=`nova list | grep livemnfs | wc -l `
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "nova list for NUM failed"
  exit 1
fi

echo "livemnfs num: ${LM_IMAGE_NUM}"
if [ ${LM_IMAGE_NUM} -gt 1 ]
then
  echo "multiple livemnfs instances : ${LM_IMAGE_NUM}"
  exit 1
fi

LIVE_MIGRATE_NETWORK=`neutron net-list | grep livemnfs | awk '{ print $2 }'`
if [ ${LM_IMAGE_NUM} -lt 1 ]
then
  nova boot --image livemnfs --flavor 3 --nic net-id=${LIVE_MIGRATE_NETWORK} livemnfs --availability-zone nova:${NOVA_HOST} --meta storage_scope=local --user-data /tmp/data.txt
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "nova boot failed"
    exit 1
  fi
fi

NOVA_BOOT_STATUS=`nova list | grep livemnfs | awk -F '|' '{print $4}'`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "nova list failed"
  exit 1
fi
if [ "x${NOVA_BOOT_STATUS}"  = "x ACTIVE" ]
then
  echo "nova livemnfs is ACTIVE"
fi


netstat -nr | grep 192.168.101.2 | grep -q ${NOVA_HOST_IP}
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "route check failed"
  route add 192.168.101.2 gw ${NOVA_HOST_IP}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "route add failed"
    exit 1
  fi
fi

grep -q "up route add 192.168.101.2 gw ${NOVA_HOST_IP}" /etc/network/interfaces
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "route not there in net-interfaces"
  echo "up route add 192.168.101.2 gw ${NOVA_HOST_IP}" >> /etc/network/interfaces
fi

ADMIN_TENANT_ID=`keystone tenant-list |grep " admin" | awk '{print $2}'`
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

CINDER_NUM=`cinder list | grep livemnfsvol | wc -l`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "cinder list failed"
  exit 1
fi

if [ ${CINDER_NUM} -eq 0 ]
then
  cinder create --display-name livemnfsvol --volume-type ocs-block-disk ${NFS_VOLUME_SIZE}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "cinder volume create failed"
    exit 1
  fi
elif [ ${CINDER_NUM} -gt 1 ]
then
  echo "more than 1 livemnfs volumes: ${CINDER_NUM}"
  exit 1
else
  echo " Only single volume"
fi

NFS_VM_ID=`nova list | grep livemnfs | awk '{printf $2}'`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "nova list failed"
  exit 1
fi

NFS_VOLUME_ID=`cinder list | grep livemnfsvol | awk '{print $2}'`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "cinder list failed"
  exit 1
fi

CINDER_OUTPUT=`cinder list | grep livemnfsvol  | awk -F '|' '{printf $8}'| tr -d ' '`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "cinder list failed"
  exit 1
fi

ITER=0
while [ $ITER -lt 10 ]
do
  ITER=`expr $ITER + 1`
  NOVA_BOOT_STATUS=`nova list | grep livemnfs | awk -F '|' '{print $4}' | tr -d ' '`
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "nova list failed"
    exit 1
  fi
  if [ "x${NOVA_BOOT_STATUS}"  = "xACTIVE" ]
  then
    echo "nova livemnfs is ACTIVE"
    break
  fi
  sleep 2
done

if [ -z ${CINDER_OUTPUT} ]
then
  echo "livemnfs-volume not attached to any instance"
  nova volume-attach ${NFS_VM_ID} ${NFS_VOLUME_ID} /dev/vdb
elif [ "x${CINDER_OUTPUT}" != "x${NFS_VM_ID}" ]
then
  echo "nova and volumes are already attached but to different ids"
  exit 1
else
  echo "nova and volume are associated to each-other"
fi
