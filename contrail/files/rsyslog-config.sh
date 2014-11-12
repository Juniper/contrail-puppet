#!/bin/bash
filename="/etc/rsyslog.conf"
rsyslog_string=$1
sed -i /'WorkDirectory/d' $filename
sed -i /'ActionQueueFileName/d' $filename
sed -i /'ActionQueueMaxDiskSpace/d' $filename
sed -i /'ActionQueueSaveOnShutdown/d' $filename
sed -i /'ActionQueueType/d' $filename
sed -i /'ActionResumeRetryCount/d' $filename
sed -i /"$rsyslog_string/d" $filename
echo '$WorkDirectory /var/tmp          # where to place spool files' >> $filename
echo '$ActionQueueFileName fwdRule1    # unique name prefix for spool files' >> $filename
echo '$ActionQueueMaxDiskSpace 1g      # 1gb space limit' >> $filename
echo '$ActionQueueSaveOnShutdown on    # save messages to disk on shutdown' >> $filename
echo '$ActionQueueType LinkedList      # run asynchronously' >> $filename
echo '$ActionResumeRetryCount -1       # infinite retries if host is down' >> $filename
echo "$rsyslog_string" >> $filename
