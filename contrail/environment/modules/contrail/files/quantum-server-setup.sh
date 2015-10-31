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

openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_port $QUANTUM_PORT
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy  keystone
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri $AUTH_PROTOCOL://$CONTROLLER:35357/v2.0/
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken identity_uri $AUTH_PROTOCOL://$CONTROLLER:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_tenant_name $SERVICE_TENANT
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_user neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_password $NEUTRON_PASSWORD
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_host $CONTROLLER
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_token $SERVICE_TOKEN
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_protocol $AUTH_PROTOCOL
####
openstack-config --set /etc/neutron/neutron.conf quotas quota_driver neutron_plugin_contrail.plugins.opencontrail.quota.driver.QuotaDriver
openstack-config --set /etc/neutron/neutron.conf QUOTAS quota_network -1
openstack-config --set /etc/neutron/neutron.conf QUOTAS quota_subnet -1
openstack-config --set /etc/neutron/neutron.conf QUOTAS quota_port -1
####
PYDIST=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin neutron_plugin_contrail.plugins.opencontrail.contrail_plugin.NeutronPluginContrailCoreV2
openstack-config --set /etc/neutron/neutron.conf DEFAULT api_extensions_path extensions:${PYDIST}/neutron_plugin_contrail/extensions
openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_host $AMQP_SERVER
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins neutron_plugin_contrail.plugins.opencontrail.loadbalancer.plugin.LoadBalancerPlugin
openstack-config --del /etc/neutron/neutron.conf service_providers service_provider
openstack-config --set /etc/neutron/neutron.conf service_providers service_provider LOADBALANCER:Opencontrail:neutron_plugin_contrail.plugins.opencontrail.loadbalancer.driver.OpencontrailLoadbalancerDriver:default
if [ -f /usr/share/neutron/neutron-dist.conf ]; then
    openstack-config --del /usr/share/neutron/neutron-dist.conf service_providers
fi
openstack-config --set /etc/neutron/neutron.conf DEFAULT log_format '%(asctime)s.%(msecs)d %(levelname)8s [%(name)s] %(message)s'

INTERNAL_VIP=${INTERNAL_VIP:-none}
if [ "$INTERNAL_VIP" != "none" ]; then
    # Openstack HA specific config
    openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_host $AMQP_SERVER
    openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_port 5673
    openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_retry_interval 1
    openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_retry_backoff 2
    openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_max_retries 0
    openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_ha_queues True
    openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_cast_timeout 30
    openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_conn_pool_size 40
    openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_response_timeout 60
    openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_thread_pool_size 70
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
