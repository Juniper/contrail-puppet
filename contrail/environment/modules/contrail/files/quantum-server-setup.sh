#!/usr/bin/env bash

set -x

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
