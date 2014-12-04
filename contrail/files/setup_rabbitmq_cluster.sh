#!/bin/bash
set -x
ostype=$1;shift
uuid=$1;shift
master=$1;shift
is_master=$1;shift
#TODO Ppvide support for centos

this_host=$(hostname)


rabbitmqctl cluster_status | grep $master
master_added=$?
rabbitmqctl cluster_status | grep $this_host
slave_added=$?

existing_uuid=$(cat /var/lib/rabbitmq/.erlang.cookie)

if [ $is_master == "yes" ] && [ $existing_uuid == $uuid ]; then
    exit 0
fi

if [ $is_master == "no" ] && [ $master_added == 0 ] && [ $slave_added == 0 ]; then
    exit 0
fi

#Stop other cfgm services,
#they will will all be restarted in config_server-setup.sh

service supervisor-config status | grep running
supervisor_config_running=$?
if [ supervisor_config_running != 0 ]; then
    eval "service supervisor-config start"
    eval "supervisorctl -s unix:///tmp/supervisord_config.sock  stop all"
fi

service supervisor-support-service status | grep running
supervisor_support_running=$?
if [ supervisor_support_running != 0 ]; then
    eval "service supervisor-support-service start"
    eval "supervisorctl -s unix:///tmp/supervisord_support_service.sock stop all"
fi

#setup and start rabbitmq
eval "sudo ufw disable"

eval "service rabbitmq-server stop"

eval "rm -rf /var/lib/rabbitmq/mnesia"
eval "epmd -kill"
echo ${uuid} > /var/lib/rabbitmq/.erlang.cookie


eval "service rabbitmq-server start"

#Print the cluste status
eval "rabbitmqctl cluster_status"


