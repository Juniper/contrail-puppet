#!/bin/bash
filename=$1
cfgm_ip=$2
rabbitmq_host_list=$3
number_of_cfgm=$4
    grep -q "tcp_listeners.*$cfgm_ip.*5672" $filename
    if [ $? -ne '0' ]; then
        if [ $number_of_cfgm -gt 1 ]; then

            echo "[" >> $filename
            echo "    { rabbit, [ {tcp_listeners, [{"\"$cfgm_ip\"", 5672}]}, {cluster_partition_handling, autoheal}," >> $filename
            echo "    {loopback_users, []}," >>$filename
            echo "    {cluster_nodes, {$rabbitmq_host_list, disc}}," >> $filename
            echo "    {vm_memory_high_watermark, 0.4}," >> $filename
            echo "    {disk_free_limit,50000000}," >> $filename
            echo "    {log_levels,[{connection, info},{mirroring, info}]}," >> $filename
            echo "    {heartbeat,600}," >> $filename
            echo "    {delegate_count,20}" >> $filename
            echo "    ]" >> $filename
            echo "    }" >> $filename
            echo "]." >> $filename
        else
            echo "[" >> $filename
            echo "    {rabbit, [ {tcp_listeners, [{\"$cfgm_ip\", 5672}]}," >> $filename
            echo "    {loopback_users, []}," >> $filename
            echo "    {log_levels,[{connection, info},{mirroring, info}]} ]" >> $filename
            echo "    }" >> $filename
            echo "]." >> $filename
        fi
    fi


