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
            echo "    {delegate_count,20}," >> $filename
	    echo "    {channel_max,5000}," >> $filename
	    echo "    {tcp_listen_options," >> $filename
	    echo "              [binary," >> $filename
   	    echo "                {packet, raw}," >> $filename
	    echo "                {reuseaddr, true}," >> $filename
            echo "                {backlog, 128}," >> $filename
            echo "                {nodelay, true}," >> $filename
            echo "                {exit_on_close, false}," >> $filename
            echo "                {keepalive, true}" >> $filename
            echo "               ]" >> $filename
            echo "     }," >> $filename
            echo "     {collect_statistics_interval, 60000}" >> $filename
            echo "    ]" >> $filename
            echo "    }," >> $filename
	    echo "    {rabbitmq_management_agent, [ {force_fine_statistics, true} ] }," >> $filename
            echo "    {kernel, [{net_ticktime,  30}]}" >> $filename
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


