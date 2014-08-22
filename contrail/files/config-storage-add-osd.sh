#!/bin/sh
set -x
JOURNAL_UUID=1a9cdde8-2313-4032-9b40-b74e27ad6ba2
OSD_TYPECODE_UUID=53158494-9eda-4e64-924f-846212338670
PART_JOURNAL_GUID=""
OSD_UUID=""
OSD_NUM=""

disk_name=$1
hostname=$2
journal_name=$3
journal_part_num=2
if [ "$#" -lt 2 ]
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

if [ -z ${journal_name} ]
then
  echo "journal name empty, using same disk"
  journal_name=${disk_name}
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

  /sbin/sgdisk -p ${disk_name}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "disk ${disk_name} doesn't exist"
    exit ${RETVAL}
  fi

  if [ ${journal_name} != ${disk_name} ]
  then
    echo "journal and data on different devices"
    pvdisplay | grep -q ${journal_name}
    RETVAL=$?
    if [ ${RETVAL} -eq 0 ] 
    then
      echo "Disk ${journal_name} is in LVM, please remove the disk from LVM"
      exit 1
    fi

    /sbin/sgdisk -p ${journal_name}
    RETVAL=$?
    if [ ${RETVAL} -ne 0 ] 
    then
      echo "disk ${journal_name} doesn't exist"
      exit ${RETVAL}
    fi
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
    OSD_UUID=${disk_uuid}
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

##TODO: Check if disk_name exists, calculate the journal size
partition_and_format_disk ()
{
  PART_JOURNAL_GUID=`uuidgen`
  OSD_UUID=`uuidgen`

  if [ "${journal_name}" = "${disk_name}" ]
  then
    /sbin/sgdisk --new=2:0:1024M --change-name=2:"ceph journal" --partition-guid=2:${PART_JOURNAL_GUID} --typecode=2:${JOURNAL_UUID} --mbrtogpt -- ${disk_name}
    RETVAL=$?
    if [ ${RETVAL} -ne 0 ] 
    then
      echo "ceph journal partition creation failed : ${RETVAL}"
      exit ${RETVAL}
    fi
  else
    echo "disks are diffeent"
    default_journal_size=1024
    num_primary=`parted -s ${journal_name} print|grep primary|wc -l`
    part_num=$(expr ${num_primary} + 1)
    echo ${part_num}
    start_part=$(expr ${default_journal_size} \* ${part_num})
    end_part=$(expr ${start_part} + ${default_journal_size})
    echo "stat-part :=> ${start_part}, end-part => ${end_part}"
    parted -s ${journal_name} mkpart primary ${start_part}M ${end_part}M
    RETVAL=$?
    if [ ${RETVAL} -ne 0 ] 
    then
      echo "ceph journal partition (${journal_name}: ${start_part}M ${end_part}M) creation failed : ${RETVAL}"
      exit ${RETVAL}
    fi
    journal_part_num=${part_num}
  fi
  /sbin/sgdisk --largest-new=1  --change-name=1:"ceph data" --partition-guid=1:${OSD_UUID} --typecode=1:${OSD_TYPECODE_UUID} --mbrtogpt -- ${disk_name}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "ceph data partition creation failed : ${RETVAL}"
    exit ${RETVAL}
  fi
  ## create FS on data partition e.g /dev/sdb1
  mkfs -t xfs -i size=2048 -f ${disk_name}1
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "mkfs for ${disk_name}1 creation failed : ${RETVAL}"
    exit ${RETVAL}
  fi
}


create_or_get_osd ()
{
  OSD_NUM=`ceph osd dump | grep -i ${OSD_UUID}  | awk '{print $1}' | sed -ne 's/.*osd.\([0-9][0-9]*\).*/\1/p'`
  if [ -z ${OSD_NUM} ]
  then 
    OSD_NUM=`ceph osd create ${OSD_UUID}`
    RETVAL=$?
    if [ ${RETVAL} -ne 0 ] 
    then
      echo "OSD creation creation failed : ${RETVAL}"
      exit ${RETVAL}
    fi
  fi

  if [ -z ${OSD_NUM} ]
  then
    echo "OSD for ${OSD_UUID} not created"
    exit 1
  fi
}

check_and_mount()
{
  if [ ! -d /var/lib/ceph/osd/ceph-${OSD_NUM} ]
  then
    mkdir -p /var/lib/ceph/osd/ceph-${OSD_NUM}
  fi

  ## Checking if /dev/sdX1 is mount on correct place
  grep /var/lib/ceph/osd/ceph-${OSD_NUM} /proc/mounts | grep -q ${disk_name}1
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]; then
    ## mount the partition 
    mount -t xfs -o noatime ${disk_name}1 /var/lib/ceph/osd/ceph-${OSD_NUM}
    RETVAL=$?
    if [ ${RETVAL} -ne 0 ] 
    then
      echo "mount for ${disk_name}1 failed : ${RETVAL}"
      exit ${RETVAL}
    fi
  else
    echo "disk ${dev_name}1 is already mounted on /var/lib/ceph/osd/ceph-${OSD_NUM}"
  fi

  if [ ! -L /var/lib/ceph/osd/ceph-${OSD_NUM}/journal ]
  then
    PART_JOURNAL_GUID=`sgdisk -i ${journal_part_num} ${journal_name} | grep "Partition unique GUID:" | awk '{ printf tolower($4)}'`
    if [ ! -z ${PART_JOURNAL_GUID} ]
    then
      if [ -L /var/lib/ceph/osd/ceph-${OSD_NUM}/journal ]
      then
        target_link=`readlink /var/lib/ceph/osd/ceph-${OSD_NUM}/journal`
        if [ "$target_link" != "/dev/disk/by-partuuid/${PART_JOURNAL_GUID}" ]
        then
          exit 99
        fi
      else
        ln -s /dev/disk/by-partuuid/${PART_JOURNAL_GUID} /var/lib/ceph/osd/ceph-${OSD_NUM}/journal
        RETVAL=$?
        if [ ${RETVAL} -ne 0 ] 
        then
          echo "creation of symbolic link failed ${part_journal_guid} : ${OSD_NUM} failed : ${RETVAL}"
            exit ${RETVAL}
        fi
      fi
    else
      echo "Journal partiion for ${disk_name} not found"
      exit 1
    fi
  else
    if [ ! -L /var/lib/ceph/osd/ceph-${OSD_NUM}/journal ]
    then
      echo "/var/lib/ceph/osd/ceph-${OSD_NUM}/journal is not a symlink"
      exit 1
    fi
  fi

}

check_and_setup_osd()
{
  ## keyring is created in the last
  if [ ! -f /var/lib/ceph/osd/ceph-${OSD_NUM}/keyring ]
  then
    ##create FS/generate osd key 
    ceph-osd --debug_osd 10 -i ${OSD_NUM} --mkfs --mkkey --osd-uuid ${OSD_UUID}
    RETVAL=$?
    if [ ${RETVAL} -ne 0 ] 
    then
      echo "ceph-osd --mkfs -mkkey failed : ${OSD_NUM} : ${OSD_UUID} failed : ${RETVAL}"
      exit ${RETVAL}
    fi
  fi

  ##Add osd key to auth list
  ceph auth add osd.${OSD_NUM} osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-${OSD_NUM}/keyring
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "ceph auth  add for : ${OSD_NUM}  failed : ${RETVAL}"
    exit ${RETVAL}
  fi

  ## Add crush bucket
  ceph osd tree | grep host | grep -q ${hostname}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    ceph osd crush add-bucket ${hostname} host
    RETVAL=$?
    if [ ${RETVAL} -ne 0 ] 
    then
      echo "ceph osd crush add-bucket for ${hostname}  failed : ${RETVAL}"
      exit ${RETVAL}
    fi
  fi

  ceph osd crush move ${hostname} root=default
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "ceph osd crush move failed for ${hostname}: ${RETVAL}"
    exit ${RETVAL}
  fi
  ceph osd crush add osd.${OSD_NUM} 1.0 host=${hostname}
}


check_disk_avail


check_disk_in_osd
RETVAL=$?
if [ ${RETVAL} -eq 0 ]
then 
  echo "Passing to next level for ${OSD_UUID}"
else 
  ceph-disk zap ${disk_name}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
    then
    echo "ceph-disk failed for ${disk_name}: ${RETVAL}"
    exit 1;
  fi

  partition_and_format_disk
fi


create_or_get_osd
echo "created OSD ${OSD_NUM} for ${OSD_UUID}"
check_and_mount
check_and_setup_osd


# Start the osd daemon

status ceph-osd id=${OSD_NUM}
RETVAL=$?
if [ ${RETVAL} -ne 0 ]
then
    start ceph-osd id=${OSD_NUM}
fi
