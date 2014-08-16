set -x
RETVAL=0
virsh_secret=$1
openstack_ip=$2
sed -i "s/^bind-address/#bind-address/" /etc/mysql/my.cnf
openstack-config --set /etc/cinder/cinder.conf DEFAULT sql_connection mysql://cinder:cinder@127.0.0.1/cinder
openstack-config --set /etc/cinder/cinder.conf DEFAULT enabled_backends rbd-disk
openstack-config --set /etc/cinder/cinder.conf DEFAULT rabbit_host  ${openstack_ip}
openstack-config --set /etc/cinder/cinder.conf rbd-disk rbd_pool volumes
openstack-config --set /etc/cinder/cinder.conf rbd-disk rbd_user volumes
openstack-config --set /etc/cinder/cinder.conf rbd-disk rbd_secret_uuid $virsh_secret
openstack-config --set /etc/cinder/cinder.conf rbd-disk glance_api_version 2
openstack-config --set /etc/cinder/cinder.conf rbd-disk volume_backend_name RBD
openstack-config --set /etc/cinder/cinder.conf rbd-disk volume_driver cinder.volume.drivers.rbd.RBDDriver
openstack-config --set /etc/glance/glance-api.conf DEFAULT default_store rbd
openstack-config --set /etc/glance/glance-api.conf DEFAULT show_image_direct_url True
openstack-config --set /etc/glance/glance-api.conf DEFAULT rbd_store_user images

. /etc/contrail/openstackrc 


cinder-manage db sync
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "cinder-manage db sync failed"
  exit 1
fi

chkconfig cinder-api on
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "chkconfig cinder-api on failed"
  exit 1
fi
chkconfig cinder-scheduler on
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "chkconfig cinder-scheduler on failed"
  exit 1
fi
chkconfig cinder-volume on
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "chkconfig cinder-volume on failed"
  exit 1
fi



#avail=`rados df | grep avail | awk  '{ print $3 }'`


service mysql restart
service cinder-api restart
service cinder-volume restart
service cinder-scheduler restart
service glance-api restart
service nova-api restart
service nova-conductor restart
service nova-scheduler restart
service libvirt-bin restart


cinder type-list | grep -q ocs-block-disk
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  cinder type-create ocs-block-disk
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "cinder type-create ocs-block-disk failed"
    exit 1
  fi
fi


cinder type-key ocs-block-disk set volume_backend_name=RBD
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "cinder type-key ocs-block-disk set volume_backend_name=RBD failed"
  exit 1
fi

#avail=$(rados df | grep avail | awk  '{ print $3 }')
#RETVAL=$?
#if [ ${RETVAL} -ne 0 ] 
#then
  #echo "rados df failed"
  ##exit 1
#fi
#
#if [ ${avail} == "" ]
#then
  ##echo "'rados df' returned avail as ${avail}"
  #exit 1;
#fi
#
## 1024*1024 => 1048576
#avail_gb=$(expr ${avail} / 1048576)
#cinder quota-update ocs-block-disk --gigabytes ${avail_gb}
#RETVAL=$?
#if [ ${RETVAL} -ne 0 ] 
#then
  #echo "cinder --gigabytes failed"
  #exit 1
##fi
#
#cinder quota-update ocs-block-disk --volumes 100
#RETVAL=$?
#if [ ${RETVAL} -ne 0 ] 
#then
  #echo "cinder --volumes failed"
  #exit 1
#fi
#cinder quota-update ocs-block-disk --snapshots 100
#RETVAL=$?
##if [ ${RETVAL} -ne 0 ] 
#then
  #echo "cinder --snapshots failed"
  #exit 1
###fi
