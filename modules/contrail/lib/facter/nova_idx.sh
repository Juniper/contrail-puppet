#!/bin/bash
#set -x
source /etc/contrail/openstackrc

idx=$(/usr/bin/nova service-list | /bin/grep $(hostname) | /bin/grep "\b$1\b" | /usr/bin/awk '{print $2}')

echo $idx
