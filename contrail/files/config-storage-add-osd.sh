#!/bin/sh
set -x
JOURNAL_UUID=1a9cdde8-2313-4032-9b40-b74e27ad6ba2
OSD_UUID=53158494-9eda-4e64-924f-846212338670

disk_name=$1
hostname=$2
if [ "$#" -ne 2 ]
then
  echo "Not sufficient number of arguments"
  exit 1
fi
if [ -z ${disk_name}  ]
then
  echo "Disk name empty, Invalid Input"
  exit 1
fi
if [ -z ${hostname} ]
then
  echo "Hostname empty, Invalid Input"
  exit 1
fi

check_disk_avail ()
{
  pvdisplay | grep -q ${disk_name}
  RETVAL=$?
  if [ ${RETVAL} -eq 0 ] 
  then
    echo "Disk ${disk_name} is in LVM, please remove the disk from LVM"
    exit 1
  fi
  return 0
}

check_disk_in_osd ()
{
  sgdisk -p ${disk_name} | grep -q "ceph data"
  RETVAL=$?

  if [ ${RETVAL} -eq 0 ] 
  then
    echo "disk ${disk_name} has \"ceph data\" parition"
    disk_uuid=`sgdisk -i 1 ${disk_name} | grep "Partition unique GUID:" | awk '{ printf $4}'`
    CMD_OUTPUT=$(ceph osd dump | grep -qi ${disk_uuid})
    RETVAL=$?
    if [ ${RETVAL} -eq 0 ] 
    then
      echo "disk ${disk_name} is already there in cluster : ${CMD_OUTPUT}"
      return 0
    else 
      echo "disk ${disk_name} is NOT there in cluster : ${CMD_OUTPUT}"
      return 1
    fi
    ## XXX: for now, exit success.
    ## TODO: check if we need to zap and re-partition the disk
  fi
  return 2
}

check_disk_avail

check_disk_in_osd
RETVAL=$?
if [ ${RETVAL} -eq 0 ]
then 
  exit 0
else 
  ceph-disk zap ${disk_name}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
    then
    echo "ceph-disk failed for ${disk_name}: ${RETVAL}"
    exit 1;
  fi
fi


part_journal_guid=`uuidgen`
osd_uuid=`uuidgen`

## TODO: Format disks

##TODO: Check if disk_name exists, calculate the journal size
/sbin/sgdisk -p ${disk_name}
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
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "ceph journal partition creation failed : ${RETVAL}"
  exit ${RETVAL}
fi
/sbin/sgdisk --largest-new=1  --change-name=1:"ceph data" --partition-guid=1:${osd_uuid} --typecode=1:${OSD_UUID} --mbrtogpt -- ${disk_name}
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "ceph data partition creation failed : ${RETVAL}"
  exit ${RETVAL}
fi

osd_num=`ceph osd create ${osd_uuid}`
if [ ${RETVAL} -ne 0 ] 
then
  echo "OSD creation creation failed : ${RETVAL}"
  exit ${RETVAL}
fi

mkdir -p /var/lib/ceph/osd/ceph-${osd_num}

## create FS on data partition e.g /dev/sdb1
mkfs -t xfs -i size=2048 -f ${disk_name}1
if [ ${RETVAL} -ne 0 ] 
then
  echo "mkfs for ${disk_name}1 creation failed : ${RETVAL}"
  exit ${RETVAL}
fi

## mount the partition 
mount -t xfs -o noatime ${disk_name}1 /var/lib/ceph/osd/ceph-${osd_num}
if [ ${RETVAL} -ne 0 ] 
then
  echo "mount for ${disk_name}1 failed : ${RETVAL}"
  exit ${RETVAL}
fi

## Create link to journal
ln -s /dev/disk/by-partuuid/${part_journal_guid} /var/lib/ceph/osd/ceph-${osd_num}/journal
if [ ${RETVAL} -ne 0 ] 
then
  echo "creation of symbolic link failed ${{part_journal_guid} : ${osd_num} failed : ${RETVAL}"
  exit ${RETVAL}
fi

##create FS/generate osd key 
ceph-osd -i ${osd_num} --mkfs --mkkey --osd-uuid ${osd_uuid}
if [ ${RETVAL} -ne 0 ] 
then
  echo "ceph-osd --mkfs -mkkey failed : ${osd_num} : ${osd_uuid} failed : ${RETVAL}"
  exit ${RETVAL}
fi

##Add osd key to auth list
ceph auth add osd.${osd_num} osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-${osd_num}/keyring
if [ ${RETVAL} -ne 0 ] 
then
  echo "ceph auth  add for : ${osd_num}  failed : ${RETVAL}"
  exit ${RETVAL}
fi

## Add crush bucket
ceph osd crush add-bucket ${hostname} host
if [ ${RETVAL} -ne 0 ] 
then
  echo "ceph osd crush add-bucket for ${hostname}  failed : ${RETVAL}"
  exit ${RETVAL}
fi
ceph osd crush move ${hostname} root=default
if [ ${RETVAL} -ne 0 ] 
then
  echo "ceph osd crush move failed for ${hostname}: ${RETVAL}"
  exit ${RETVAL}
fi
ceph osd crush add osd.${osd_num} 1.0 host=${hostname}


# Start the osd daemon
start ceph-osd id=${osd_num}
