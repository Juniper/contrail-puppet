#!/bin/bash
set -x

service neutron-server status | grep running
neutron_server_status=$?
if [ $neutron_server_status -eq 0 ]; then
    service neutron-server stop
fi
