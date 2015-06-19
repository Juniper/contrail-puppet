#!/bin/sh
set -x

disk_names=$1

## Segregation of journal disk and data disk
osd_disk=`echo ${disk_names} | awk -F ':' '{printf $1}'`
journal_disk=`echo ${disk_names} | awk -F ':' '{printf $2}'`

echo "OSD disk : ${osd_disk}"
echo "Journal disk : ${journal_disk}"

## Check for valid inputs.
## NOTE: Journal disk could be empty, same disk is to be used for journal
## NOTE: as well
if [ -z ${osd_disk}  ]
then
  echo "Disk name empty, Invalid Input"
  exit 1
fi

check_disk_avail ()
{
  ## Check if disk exists
  disk_name=$1
  /sbin/fdisk -l ${disk_name}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "disk ${disk_name} doesn't exist"
    exit ${RETVAL}
  fi

  ## Check if disk is a part of LVM
  pvdisplay | grep -q ${disk_name}
  RETVAL=$?
  if [ ${RETVAL} -eq 0 ] 
  then
    echo "Disk ${disk_name} is in LVM, please remove the disk from LVM"
    exit 1
  fi

  return 0
}

clean_disk_parts()
{
  ## Get the disk GUID and check against existing cleaned disks.
  ## This is to avoid cleaning a disk multiple times.
  disk_name=$1
  disk_guid=`sgdisk -p ${disk_name}  | grep "Disk identifier (GUID):" | awk '{printf $4}'`

  if [ -f /etc/contrail/config-storage-clean-disk.out ] 
  then
    ## Check if disk GUID exists in cleaned disks list
    grep -q ${disk_guid} /etc/contrail/config-storage-clean-disk.out
    RETVAL=$?
    if [ ${RETVAL} -eq 0 ]
    then
      echo "disk already clean ${disk_name}/${disk_guid}"
      return 0
    fi
  fi

  ## clean partition table
  dd if=/dev/zero of=${disk_name} bs=512 count=1
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    echo "dd failed for ${disk_name}"
    exit ${RETVAL}
  fi

  # convert the disk to GPT
  parted -s ${disk_name} mklabel gpt
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    echo "parted mklabel failed for ${disk_name}"
    exit ${RETVAL}
  fi

  ceph-disk zap ${disk_name}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    echo "ceph-disk zap failed for ${disk_name}"
    exit ${RETVAL}
  fi

  new_disk_guid=`sgdisk -p ${disk_name}  | grep "Disk identifier (GUID):" | awk '{printf $4}'`

  ## put disk GUID to clean-up data-base 
  echo "${new_disk_guid}" >> /etc/contrail/config-storage-clean-disk.out
}

## CHeck the  data disks
check_disk_avail ${osd_disk}
clean_disk_parts ${osd_disk}

## clean journal disk as well.
if [ x${journal_disk} != x"" ]
then
  echo "cleaning journal disks"
  ## Check journal disks as well
  check_disk_avail ${journal_disk}
  clean_disk_parts ${journal_disk}
fi
