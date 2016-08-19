#!/bin/sh
set -x
virsh_secret=$1
## TODO: This should be rabbit-mq server ip address instead of
## openstack ip address
openstack_ip=$2

openstack-config --set /etc/nova/nova.conf DEFAULT cinder_endpoint_template "http://${openstack_ip}:8776/v1/%(project_id)s"
openstack-config --set /etc/contrail/contrail-storage-nodemgr.conf DEFAULTS disc_server_ip ${openstack_ip}


chkconfig tgt on
chkconfig cinder-volume on

service tgt restart
service cinder-volume restart
service libvirt-bin restart
service nova-compute restart
service contrail-storage-stats restart
