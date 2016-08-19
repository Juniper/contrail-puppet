#!/bin/bash
set -x
rabbit_list=$1;shift

echo ${rabiit_list[@]}
for rabbit_host in ${rabbit_list[@]}; do
    rabbitmqctl cluster_status | grep $rabbit_host
    added_to_cluster=$?
    if [ $added_to_cluster != 0 ]; then
	exit 1
    fi
done

