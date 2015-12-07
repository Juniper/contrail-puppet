#!/usr/bin/env bash

CONF_DIR=/etc/contrail
set -x

source /etc/contrail/ctrl-details

# Check if ADMIN/SERVICE Password has been set
SERVICE_TOKEN=${SERVICE_TOKEN:-$(cat $CONF_DIR/service.token)}
INTERNAL_VIP=${INTERNAL_VIP:-none}

controller_ip=$CONTROLLER
if [ "$INTERNAL_VIP" != "none" ]; then
    controller_ip=$INTERNAL_VIP
fi

openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri $AUTH_PROTOCOL://$CONTROLLER:35357/v2.0/
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_host $CONTROLLER
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_token $SERVICE_TOKEN
PYDIST=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")
openstack-config --set /etc/neutron/neutron.conf DEFAULT api_extensions_path extensions:${PYDIST}/neutron_plugin_contrail/extensions
if [ -f /usr/share/neutron/neutron-dist.conf ]; then
    openstack-config --del /usr/share/neutron/neutron-dist.conf service_providers
fi


# Add respawn in nova-compute upstart script
net_svc_upstart='/etc/init/neutron-server.conf'
if [ -f $net_svc_upstart ]; then
    ret_val=`grep "^respawn" $net_svc_upstart > /dev/null;echo $?`
    if [ $ret_val == 1 ]; then
      sed -i 's/pre-start script/respawn\n&/' $net_svc_upstart
      sed -i 's/pre-start script/respawn limit 10 90\n&/' $net_svc_upstart
    fi
fi
