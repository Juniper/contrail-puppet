#!/bin/sh

set -x
RETVAL=0
## TODO: change arguments from positional to options
## server-ip is required to download live-migration QCOW2 image.
SERVER_IP=$1
## nova host is where NFS VM for Live-Migration is spawned
NOVA_HOST=$2
## number of OSDs configured by admin. this is check if all the OSDs
## has came up. else we will wait for them to come-up
NUM_TARGET_OSD=$3

OPENSTACK_IPADDRESS=$4
NOVA_HOST_IP=$5
ip addr | grep -q ${OPENSTACK_IPADDRESS}
RETVAL=$?
if [ ${RETVAL} -ne 0 ]
then
  echo "I am not the storage-master"
  exit 0
fi

LIVEMNFS_IP=192.168.101.3
LIVEMNFS_NETWORK=192.168.101.0/24

## Check if "ceph -s" is returing or it is waiting for other monitors to be up
timeout 10 ceph -s 

RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "ceph -s failed"
  exit 1
fi

## check if all the OSDs configured are in and up. This is required as we
## need to create 15% of total available space as volume for NFS VM
## for Live-Migration
## TODO: this may give wrong output if ceph -s failed. change this to 
## TODO: multiple lines/commands. and check for failures
NUM_CURR_OSD=` ceph -s | grep "osdmap" | awk '{printf $7}'`
echo "current-osd : ${NUM_CURR_OSD}, target: ${NUM_TARGET_OSD}"
if [ "x${NUM_CURR_OSD}" != "x${NUM_TARGET_OSD}" ]
then
    echo "not all OSDs are up"
    exit 1
fi

## Check if we are able to resolve ip address of nova-host
host ${NOVA_HOST} 
RETVAL=$?
if [ ${RETVAL} -ne 0 ]
then
  echo "host resolution failed"
  exit 1
fi

## Get the ip address of nova-host.
## NOTE: we already checked about the ip resolution. so awk must
## NOTE: give correct results
#NOVA_HOST_IP=`host ${NOVA_HOST} | awk '{printf $4}'`

## GET the UIDs/GIDs of required users/groups. we generate a file out of it.
nova_uid=`id -u nova`
dnsmasq_uid=`id -u libvirt-dnsmasq`
qemu_uid=`id -u libvirt-qemu`
nova_gid=`getent group nova | awk -F: '{printf $3}'`
kvm_gid=`getent group kvm| awk -F: '{printf $3}'`
virtd_gid=`getent group libvirtd| awk -F: '{printf $3}'`

## generate the file to be fed to nova boot for NFS VM
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

sync

. /etc/contrail/openstackrc
## Check if we have already created the image
## TODO: 1. break command to check failures.
## TODO: 2. check for complete name of livemnfs. currently it may match
## TODO:    with livemnfs-not-me
NUM_IMAGE_LIVEMNFS=`nova image-list | grep livemnfs | wc -l`

## check if we need to download the qcow2 image again ?
if [ ${NUM_IMAGE_LIVEMNFS} -eq 1 ]
then
  DOWNLOAD_REQD=0
## checking if we have multiple livemnfs matches.
## TODO: this should not have happened, and it should be handled appropriately.
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

  ## Download the qcow2-gzipped image
  wget -q http://${SERVER_IP}/contrail/images/livemnfs.qcow2.gz -O /tmp/livemnfs.qcow2.gz
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    echo "wget failed"
    exit 1
  fi
  ## remove old qcow2 image, if any
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
  ## create image using newly doownloaded image.
  glance image-create --name livemnfs --disk-format qcow2 --container-format ovf --file /tmp/livemnfs.qcow2 --is-public True
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "Glance image create failed"
    exit 1
  fi
fi

NOVA_IMAGE_STATUS=`nova image-list | grep livemnfs | awk -F '|' '{print $4}' | tr -d ' '`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "nova image-list failed"
  exit 1
fi

if [ "x${NOVA_IMAGE_STATUS}"  = "xACTIVE" ]
then
  echo "nova image livemnfs is ACTIVE"
else
  echo "nova image livemnfs is not ACTIVE"
  exit 2
fi

## create network for livemnfs
## TODO: check for complete livemnfs only.
## TODO: break command to check return status of commands
LIVE_MIGRATE_NETWORK_NUM=`neutron net-list | grep livemnfs | wc -l `
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "neutron net-list failed"
  exit 1
fi

## get the uuid of livemnfs network
LIVE_MIGRATE_NETWORK=`neutron net-list | grep livemnfs | awk '{ print $2 }'`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "neutron net-list failed"
  exit 1
fi

## Though it is not possible, still checking for error case.
## we can't have multiple netwrok with livemnfs as name
if [ ${LIVE_MIGRATE_NETWORK_NUM} -gt 1 ]
then
  echo "more than 1 livemnfs networks"
  exit 1
fi

echo "LM netowrk ${LIVE_MIGRATE_NETWORK} ${LIVE_MIGRATE_NETWORK_NUM}"
## if don't have network, then create it.
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

## Check for livemnfs subnet
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
  ## as of now, we have fixed subnet to 192.168.101.0/24.
  ## TODO: take subnet as argument
  neutron subnet-create --name livemnfs livemnfs ${LIVEMNFS_NETWORK}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "neutron subnet-create failed"
    exit 1
  fi
fi

## checking if host for NFS VM is a compute or not.
## TODO: break into multiple commands to check individual comand return status
nova-manage host list | grep -w ${NOVA_HOST} | awk '{print $2}' | grep -q nova
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "nova-manage host list doesn't have host/nova"
  exit 1
fi


## check if we have booted the livemnfs image or not 
LM_IMAGE_NUM=`nova list | grep livemnfs | wc -l `
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "nova list for NUM failed"
  exit 1
fi

echo "livemnfs num: ${LM_IMAGE_NUM}"
## its error to have multiple livemnfs instances
if [ ${LM_IMAGE_NUM} -gt 1 ]
then
  echo "multiple livemnfs instances : ${LM_IMAGE_NUM}"
  exit 1
fi

## get the livemnfs network UUID for booting the image
## TODO: break the command 
## TODO: check for complete name
LIVE_MIGRATE_NETWORK=`neutron net-list | grep livemnfs | awk '{ print $2 }'`
if [ ${LM_IMAGE_NUM} -lt 1 ]
then
  ## boot the image
  ## TODO: using fixed flavor right now. fab created a new flavor
  ## TODO:  based on hardware specs.
  nova boot --image livemnfs --flavor 3 --nic net-id=${LIVE_MIGRATE_NETWORK} livemnfs --availability-zone nova:${NOVA_HOST} --meta storage_scope=local --user-data /tmp/data.txt
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "nova boot failed"
    exit 1
  fi
fi

## get the current status of livemnfs instance.  
NOVA_BOOT_STATUS=`nova list | grep livemnfs | awk -F '|' '{print $4}'| tr -d ' '`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "nova list failed"
  exit 1
fi

if [ ! "x${NOVA_BOOT_STATUS}"  = "xACTIVE" ]
then
  echo "nova livemnfs is not ACTIVE"
  exit 1
fi


## we need to create route for NFS VM ip address.
## checking if route is already present ?
## TODO: we are using FIXED ip address right now. move this to
## TODO: dynamic ip address.
netstat -nr | grep ${LIVEMNFS_IP} | grep -q ${NOVA_HOST_IP}
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "route check failed"
  ## add the route
  route add ${LIVEMNFS_IP} gw ${NOVA_HOST_IP}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "route add failed"
    exit 1
  fi
fi

## Check if route is added to startup scripts. this is required 
## to bring-up route on system start-up
grep -q "up route add ${LIVEMNFS_IP} gw ${NOVA_HOST_IP}" /etc/network/interfaces
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "route not there in net-interfaces"
  echo "up route add ${LIVEMNFS_IP} gw ${NOVA_HOST_IP}" >> /etc/network/interfaces
fi


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

## get the number of livemnfsvol
## TODO: break command
## TODO: check for livemnfsvol only
CINDER_NUM=`cinder list | grep livemnfsvol | wc -l`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "cinder list failed"
  exit 1
fi

## if we don't have livemnfsvol, create it
if [ ${CINDER_NUM} -eq 0 ]
then
  cinder create --display-name livemnfsvol --volume-type ocs-block-disk ${NFS_VOLUME_SIZE}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "cinder volume create failed"
    exit 1
  fi
## its error to have multiple  livemnfsvol
elif [ ${CINDER_NUM} -gt 1 ]
then
  echo "more than 1 livemnfs volumes: ${CINDER_NUM}"
  exit 1
else
  echo " Only single volume"
fi

## get the livemnfs instance UUID, this is required for attaching volume to it
NFS_VM_ID=`nova list | grep livemnfs | awk '{printf $2}'`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "nova list failed"
  exit 1
fi

## get the livemnfsvol UUID, it is required for attaching to instance
NFS_VOLUME_ID=`cinder list | grep livemnfsvol | awk '{print $2}'`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "cinder list failed"
  exit 1
fi

## get the status of livemnfs volume, ensure it is active
CINDER_OUTPUT=`cinder list | grep livemnfsvol  | awk -F '|' '{printf $8}'| tr -d ' '`
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "cinder list failed"
  exit 1
fi

## Wait for 20 seconds, and keep checking for instance status
## TODO: break command
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
  ## if instance becomes ACTIVE, break out of loop.
  if [ "x${NOVA_BOOT_STATUS}"  = "xACTIVE" ]
  then
    echo "nova livemnfs is ACTIVE"
    break
  fi
  sleep 2
done

## Attach livemnfsvol volume to livemnfs instance.
## TODO: Check the nova instance status again, in case VM is still not active.
if [ -z ${CINDER_OUTPUT} ]
then
  echo "livemnfs-volume not attached to any instance"
  nova volume-attach ${NFS_VM_ID} ${NFS_VOLUME_ID} /dev/vdb
  ## Exit after attach, allow VM to settle
  exit 1
elif [ "x${CINDER_OUTPUT}" != "x${NFS_VM_ID}" ]
then
  echo "nova and volumes are already attached but to different ids"
  exit 1
else
  echo "nova and volume are associated to each-other"
fi

## VM should be settled by now, try mount
ping -c 5 ${LIVEMNFS_IP}
RETVAL=$?
if [ $RETVAL -eq 0 ]
then 
  mkdir -p /tmp/livemnfsvol
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    echo "mkdir failed"
    exit ${RETVAL}
  fi
  mount ${LIVEMNFS_IP}:/livemnfsvol /tmp/livemnfsvol
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    echo "mount to livemnfsvol failed"
    nova stop livemnfs
    sleep 5
    nova start livemnfs
    # exit with error to come back 
    exit 1
  else
    # unmount it and exit
    umount /tmp/livemnfsvol
    RETVAL=$?
    if [ ${RETVAL} -ne 0 ]
    then
      echo "mkdir failed"
      exit ${RETVAL}
    fi
  fi
else
  exit 1
fi
