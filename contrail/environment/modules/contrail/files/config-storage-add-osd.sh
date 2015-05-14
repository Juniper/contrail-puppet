#!/bin/sh
set -x

## Following uuid's are only meant for identification, as of now these
## are not used anywhere.
JOURNAL_UUID=1a9cdde8-2313-4032-9b40-b74e27ad6ba2
OSD_TYPECODE_UUID=53158494-9eda-4e64-924f-846212338670
PART_JOURNAL_GUID=""
OSD_UUID=""
OSD_NUM=""

## Diskname to be added to ceph cluster
disk_name=$1
## What is my hostname, this needed for ceph osd tree.
hostname=$2
## journal disk-name, this could be same as disk or different disk
journal_name=$3
## initial value is 2, if disk and journal are on same disk.
journal_part_num=2

## check number of arguments
if [ "$#" -lt 2 ]
then
  echo "Not sufficient number of arguments"
  exit 1
fi

## NULL check for disk-name
if [ -z ${disk_name}  ]
then
  echo "Disk name empty, Invalid Input"
  exit 1
fi
## NULL check for hostname
if [ -z ${hostname} ]
then
  echo "Hostname empty, Invalid Input"
  exit 1
fi

## if journal_name is not provided, use disk-name as journal-name
if [ -z ${journal_name} ]
then
  echo "journal name empty, using same disk"
  journal_name=${disk_name}
fi

timeout 10 ceph -s

RETVAL=$?
if [ ${RETVAL} -ne 0 ]
then
  echo "ceph -s failed"
  exit 1
fi

check_disk_avail ()
{

  ## check if disk is added to LVM, if yes, exit with ERROR
  pvdisplay | grep -q ${disk_name}
  RETVAL=$?
  if [ ${RETVAL} -eq 0 ] 
  then
    echo "Disk ${disk_name} is in LVM, please remove the disk from LVM"
    exit 1
  fi

  ## Check if disk is valid and exists
  /sbin/sgdisk -p ${disk_name}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "disk ${disk_name} doesn't exist"
    exit ${RETVAL}
  fi

  ## if journal is different disk, check for LVM with journal disk and
  ##  existance
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
  ## check if any of partitions have "ceph data". while adding a new disk
  ## to ceph cluster, we add "ceph data" to partition description
  sgdisk -p ${disk_name} | grep -q "ceph data"
  RETVAL=$?

  if [ ${RETVAL} -eq 0 ] 
  then
    echo "disk ${disk_name} has \"ceph data\" parition"
    ## Get the UUID of first partition
    ## TODO: break command into multiple checks, if sgdisk fails, awk may
    ## TODO: provide wrong results
    disk_uuid=`sgdisk -i 1 ${disk_name} | grep "Partition unique GUID:" | awk '{ printf $4}'`

    ## Check if UUID is there in "ceph osd dump". UUIDs added to ceph
    ## cluster is as partition UUID
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
  fi
  ## disk doesn't have any ceph data partition
  return 2
}

##TODO: Check if disk_name exists, calculate the journal size
partition_and_format_disk ()
{
  ## Get a new UUID for journal partition
  PART_JOURNAL_GUID=`uuidgen`
  OSD_UUID=`uuidgen`

  ## Check if journal and disk are on same disk
  if [ "${journal_name}" = "${disk_name}" ]
  then
    ## If yes, create a partition of 1GB
    ## TODO: take journal size from config-file or input parameter
    /sbin/sgdisk --new=2:0:1024M --change-name=2:"ceph journal" --partition-guid=2:${PART_JOURNAL_GUID} --typecode=2:${JOURNAL_UUID} --mbrtogpt -- ${disk_name}
    RETVAL=$?
    if [ ${RETVAL} -ne 0 ] 
    then
      echo "ceph journal partition creation failed : ${RETVAL}"
      exit ${RETVAL}
    fi
  else
    echo "disks are different"
    ## TODO: taken journal size from config-file or input parameter
    default_journal_size=1024
    ## Find out existing number of partitions
    num_primary=`parted -s ${journal_name} print|grep primary|wc -l`
    ## What should be the next partition number
    ## TODO: This logic is error prone. it simply adds one, doesn't check
    ## if partition is already created
    part_num=$(expr ${num_primary} + 1)
    echo ${part_num}
    ## Start size of journal partition
    start_part=$(expr ${default_journal_size} \* ${part_num})
    ## End Size of journal partition, END=> START + JOUNRAL SIZE
    end_part=$(expr ${start_part} + ${default_journal_size})
    echo "stat-part :=> ${start_part}, end-part => ${end_part}"
    ## Create a partition using parted
    parted -s ${journal_name} mkpart primary ${start_part}M ${end_part}M
    RETVAL=$?
    if [ ${RETVAL} -ne 0 ] 
    then
      echo "ceph journal partition (${journal_name}: ${start_part}M ${end_part}M) creation failed : ${RETVAL}"
      exit ${RETVAL}
    fi
    journal_part_num=${part_num}
  fi
  ## By now, we have journal partition, create data partition,
  ## name it with "ceph data", to identify it easier.
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
  ## find out the OSD number assigned to OSD_UUID
  ## TODO: check if one command fails.
  OSD_NUM=`ceph osd dump | grep -i ${OSD_UUID}  | awk '{print $1}' | sed -ne 's/.*osd.\([0-9][0-9]*\).*/\1/p'`
  ## if zero/empty, then create a OSD for OSD_UUID
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

  ## OSD_NUM still empty/zero, creation failed
  if [ -z ${OSD_NUM} ]
  then
    echo "OSD for ${OSD_UUID} not created"
    exit 1
  fi
}

check_and_mount()
{
  ## Create ceph data directory for mount
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

  ## check symlink for journal
  if [ ! -L /var/lib/ceph/osd/ceph-${OSD_NUM}/journal ]
  then
    ## if not, get partition GUID for symlink.
    ## NOTE: we are not using disk names here instead using UUID
    PART_JOURNAL_GUID=`sgdisk -i ${journal_part_num} ${journal_name} | grep "Partition unique GUID:" | awk '{ printf tolower($4)}'`
    if [ ! -z ${PART_JOURNAL_GUID} ]
    then
      ## this can't happen, still added before creation of link
      if [ -L /var/lib/ceph/osd/ceph-${OSD_NUM}/journal ]
      then
        ## if exists, check newlink and existing link are same
        target_link=`readlink /var/lib/ceph/osd/ceph-${OSD_NUM}/journal`
        if [ "$target_link" != "/dev/disk/by-partuuid/${PART_JOURNAL_GUID}" ]
        then
          ## This is error case, exiting for now, else we should remove link
          ## and create a new link
          exit 99
        fi
      else
        ## create symlink 
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
    ## TODO: this check should be removed
    if [ ! -L /var/lib/ceph/osd/ceph-${OSD_NUM}/journal ]
    then
      echo "/var/lib/ceph/osd/ceph-${OSD_NUM}/journal is not a symlink"
      exit 1
    fi
  fi

}

check_and_setup_osd()
{
  ## keyring is created in the last, so check if this has been created,
  ## if yes, then ceph osd mkfs mkkey has been ran once.
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

  ## Add osd key to auth list
  ## TOO: there should be a check before adding it ot auth list
  ceph auth list | grep -wq "^osd.${OSD_NUM}"
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    ceph auth add osd.${OSD_NUM} osd 'allow *' mon 'allow profile osd' -i /var/lib/ceph/osd/ceph-${OSD_NUM}/keyring
    RETVAL=$?
    if [ ${RETVAL} -ne 0 ] 
    then
      echo "ceph auth  add for : ${OSD_NUM}  failed : ${RETVAL}"
      exit ${RETVAL}
    fi
  fi

  ## active file is created by ceph-disk, so we are creating is manually.
  ##  as of now, this file is used by ceph-stats daemon
  if [ ! -f /var/lib/ceph/osd/ceph-${OSD_NUM}/active ]
  then
    echo "ok" > /var/lib/ceph/osd/ceph-${OSD_NUM}/active
    RETVAL=$?
    if [ ${RETVAL} -ne 0 ] 
    then
      echo "active file creation for : ${OSD_NUM} : ${OSD_UUID} failed : ${RETVAL}"
      exit ${RETVAL}
    fi
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

    ceph osd crush move ${hostname} root=default
    RETVAL=$?
    if [ ${RETVAL} -ne 0 ] 
    then
      echo "ceph osd crush move failed for ${hostname}: ${RETVAL}"
      exit ${RETVAL}
    fi
  fi
  ceph osd tree | grep -qw osd.${OSD_NUM}
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ]
  then
    ## disk weight is based on disk size. for 800GB disk, weight is ~ .80
    disk_size=`fdisk -s ${disk_name}`
    disk_weight=$(awk "BEGIN {printf \"%.2f\", ${disk_size}  / (1024 * 1024 * 1024)}")
    ## TODO: check if disk already added to osd tree with correct weight
    ceph osd crush add osd.${OSD_NUM} ${disk_weight} host=${hostname}
  fi
}

## Following is the flow of addiing/Checking OSDs

## preliminary checks, existance, LVM
check_disk_avail


## Check if disk is already available in ceph cluster
check_disk_in_osd
RETVAL=$?
if [ ${RETVAL} -eq 0 ]
then 
  echo "Passing to next level for ${OSD_UUID}"
else 
  ## if not, create data/journal partition and create filesystem on them
  partition_and_format_disk
fi


## Either get the OSD number or create a new and get it
create_or_get_osd
echo "created OSD ${OSD_NUM} for ${OSD_UUID}"
## create symlink for journal, mount the data partition
## @/var/lib/ceph/osd/ceph-<OSD-NUM>
check_and_mount

## now create ceph file-system @/var/lib/ceph/osd/ceph-<OSD-NUM>,
## add keyring to the auth-list
## create active file with "ok" contents
## create host bucket in crush, if required
## move host bucket under root
## calculate osd weight based on disk size
## add osd to crush
check_and_setup_osd


# Start the osd daemon

## Check the status of ceph-osd daemon, start if required
## NOTE: starting this way dooesn't start the daemons on start-up.
## NOTE: daemons will be started by puppet at boot time.
status ceph-osd id=${OSD_NUM}
RETVAL=$?
if [ ${RETVAL} -ne 0 ]
then
    start ceph-osd id=${OSD_NUM}
fi
