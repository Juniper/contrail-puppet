#!/bin/sh
set -x
JOURNAL_UUID=1a9cdde8-2313-4032-9b40-b74e27ad6ba2
OSD_UUID=53158494-9eda-4e64-924f-846212338670

disk_name=$1
hostname=$2
part_journal_guid=`uuidgen`
osd_uuid=`uuidgen`

## TODO: Format disks

##TODO: Check if disk_name exists, calculate the journal size
sgdisk -p ${disk_name}
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "disk ${disk_name} doesn't exist"
  exit ${RETVAL}
fi

sgdisk -p ${disk_name} | grep -q "ceph data"
RETVAL=$?

if [ ${RETVAL} -eq 0 ] 
then
  echo "disk ${disk_name} has \"ceph data\" parition"
  disk_uuid=`sgdisk -i 1 ${disk_name} | grep "Partition unique GUID:" | awk '{ printf $4}'`
  CMD_OUTPUT=`ceph osd dump | grep -i ${disk_uuid}`
  RETVAL=$?
  if [ ${RETVAL} -eq 0 ] 
  then
    echo "disk ${disk_name} is already there in cluster : ${CMD_OUTPUT}"
  fi
  ## XXX: for now, exit success.
  ## TODO: check if we need to zap and re-partition the disk
  exit 0
fi

## Create partitions, TODO: Check return status of commands
/sbin/sgdisk --new=2:0:1024M --change-name=2:"ceph journal" --partition-guid=2:${part_journal_guid} --typecode=2:${JOURNAL_UUID} --mbrtogpt -- ${disk_name}
/sbin/sgdisk --largest-new=1  --change-name=1:"ceph data" --partition-guid=1:${osd_uuid} --typecode=1:${OSD_UUID} --mbrtogpt -- ${disk_name}

osd_num=`ceph osd create ${osd_uuid}`

mkdir -p /var/lib/ceph/osd/ceph-${osd_num}

## create FS on data partition e.g /dev/sdb1
mkfs -t xfs -i size=2048 -f ${disk_name}1

## mount the partition 
mount -t xfs -o noatime ${disk_name}1 /var/lib/ceph/osd/ceph-${osd_num}

## Create link to journal
ln -s /dev/disk/by-partuuid/${part_journal_guid} /var/lib/ceph/osd/ceph-${osd_num}/journal

##create FS/generate osd key 
ceph-osd -i ${osd_num} --mkfs --mkkey --osd-uuid ${osd_uuid}

##Add osd key to auth list
ceph auth add osd.${osd_num} osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-${osd_num}/keyring

## Add crush bucket
ceph osd crush add-bucket ${hostname} host
ceph osd crush move ${hostname} root=default
ceph osd crush add osd.${osd_num} 1.0 host=${hostname}


# Start the osd daemon
start ceph-osd id=${osd_num}
