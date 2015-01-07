#!/bin/bash
set -x
master=$1;shift
this_host=$1;shift
rabbit_list=$1;shift

rm -rf /var/lib/rabbitmq/mnesia
service supervisor-support-service restart
#service rabbitmq-server restart

echo ${rabiit_list[@]}
for rabbit_host in ${rabbit_list[@]}; do
    rabbitmqctl cluster_status | grep $rabbit_host
    added_to_cluster=$?
    if [ $added_to_cluster != 0 ]; then
	exit 1
    fi
done

