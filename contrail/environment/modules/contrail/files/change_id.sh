#!/bin/sh

GLANCE_UID=495
GLANCE_GID=495
USER_NAME=glance

CUR_GLANCE_UID=`id -u ${USER_NAME}`

if [ $? != 0 ]
then
  echo "user doesn't exists, we are good"
  exit 0
fi

echo "UID => $CUR_GLANCE_UID"
CUR_GLANCE_GID=`id -g ${USER_NAME}`

if [ "x${CUR_GLANCE_UID}" = "x${GLANCE_UID}" ]
then
  echo "UID (${CUR_GLANCE_UID}, ${GLANCE_UID}) are same "
  exit 0
fi

echo "UID are different $CUR_GLANCE_UID, $GLANCE_UID, possible upgrade"

echo "Stopping Glance services"
service glance-api stop
service glance-registry stop

sleep 3

echo "Starting to change uid/gid"

c=1
while [ $c -le 5 ]
do
  echo "Try => $c"
  OLD_UID_COUNT=`find / -path /media -prune -o -path /proc -prune -o  -user ${CUR_GLANCE_UID} -print | wc -l`
  if [ "x${OLD_UID_COUNT}" != "x0" ]
  then
    find / -path /media -prune -o -path /proc -prune -o  -user ${CUR_GLANCE_UID} -exec chown -h ${GLANCE_UID} {} \;
    find / -path /media -prune -o -path /proc -prune -o  -group ${CUR_GLANCE_GID} -exec chgrp -h ${GLANCE_GID} {} \;
  else
    echo "No more files to change"
    break
  fi
  c=`expr $c + 1`
done

OLD_UID_COUNT=`find / -path /media -prune -o -path /proc -prune -o  -user ${CUR_GLANCE_UID} -print | wc -l`
echo "old-uid-count => ${OLD_UID_COUNT}"
if [ "x${OLD_UID_COUNT}" != "x0" ]
then
  echo "Not all files changed, FAILED"
  exit 1
fi


echo "Changed uid/gid"
usermod -u $GLANCE_UID $USER_NAME
groupmod -g $GLANCE_GID $USER_NAME
usermod -g $GLANCE_UID $USER_NAME

echo "Re-starting Glance services"
service glance-api restart
service glance-registry restart
