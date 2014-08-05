set -x
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
cinder type-create ocs-block-disk
cinder type-key ocs-block-disk set volume_backend_name=RBD

#avail=$(rados df | grep avail | awk  '{ print $3 }')
## 1024*1024 => 1048576
#avail_gb=$(expr ${avail} / 1048576)
#cinder quota-update ocs-block-disk --gigabytes ${avail_gb}

cinder-manage db sync

service mysql restart
chkconfig cinder-api on
service cinder-volume restart
service glance-api restart
service nova-api restart
service nova-conductor restart
service nova-scheduler restart
service libvirt-bin restart
service nova-api restart
service nova-scheduler restart
