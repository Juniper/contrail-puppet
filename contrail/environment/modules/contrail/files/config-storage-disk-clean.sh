#!/bin/sh
set -x

disk_names=$1

osd_disk=`echo ${disk_names} | awk -F ':' '{printf $1}'`
journal_disk=`echo ${disk_names} | awk -F ':' '{printf $2}'`

echo "OSD disk : ${osd_disk}"
echo "Journal disk : ${journal_disk}"

if [ -z ${osd_disk}  ]
then
  echo "Disk name empty, Invalid Input"
  exit 1
fi

check_disk_avail ()
{
  disk_name=$1
  /sbin/fdisk -l ${disk_name}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "disk ${disk_name} doesn't exist"
    exit ${RETVAL}
  fi

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
  disk_name=$1
  disk_guid=`sgdisk -p ${disk_name}  | grep "Disk identifier (GUID):" | awk '{printf $4}'`

  if [ -f /etc/contrail/config-storage-clean-disk.out ] 
  then
    grep -q ${disk_guid} /etc/contrail/config-storage-clean-disk.out
    RETVAL=$?
    if [ ${RETVAL} -eq 0 ]
    then
      echo "disk already clean ${disk_name}/${disk_guid}"
      return 0
    fi
  fi
  
  dd if=/dev/zero of=${disk_name} bs=512 count=1
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    echo "dd failed for ${disk_name}"
    exit ${RETVAL}
  fi
  
  parted -s ${disk_name} mklabel gpt
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    echo "parted mklabel failed for ${disk_name}"
    exit ${RETVAL}
  fi
  
  new_disk_guid=`sgdisk -p ${disk_name}  | grep "Disk identifier (GUID):" | awk '{printf $4}'`

  echo "${new_disk_guid}" >> /etc/contrail/config-storage-clean-disk.out
}

check_disk_avail ${osd_disk}
clean_disk_parts ${osd_disk}

if [ x${journal_disk} != x"" ]
then
  echo "cleaning journal disks"
  check_disk_avail ${journal_disk}

  clean_disk_parts ${journal_disk}
fi
