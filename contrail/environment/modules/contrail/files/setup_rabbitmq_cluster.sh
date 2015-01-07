#!/bin/bash
set -x
ostype=$1;shift
uuid=$1;shift
master=$1;shift
is_master=$1;shift
openstack_ha=$1;shift

#TODO Ppvide support for centos

this_host=$(hostname)

#Stop other cfgm services,
#they will will all be restarted in config_server-setup.sh

service supervisor-support-service status | grep running
supervisor_config_running=$?
if [ supervisor_config_running != 0 ]; then
    eval "service supervisor-support-service start"
    eval "supervisorctl -s http://localhost:9004 stop all"
fi

#setup and start rabbitmq
eval "sudo ufw disable"
eval "rm -rf /var/lib/rabbitmq/mnesia"

eval "service rabbitmq-server stop"
eval "epmd -kill"
echo ${uuid} > /var/lib/rabbitmq/.erlang.cookie


eval "service rabbitmq-server start"

#if openstack ha is enabled
if [ $openstack_ha == "yes" ] ; then
	#setup rabbitmq ha policy
	rabbitmqctl set_policy HA-all \"\" '{\"ha-mode\":\"all\",\"ha-sync-mode\":\"automatic\"}'

	#set tcp keepalive
	grep '^net.ipv4.tcp_keepalive_time' /etc/sysctl.conf
	is_keepalive_present=$?
	if [ $is_keepalive_present != 0 ]; then
		echo 'net.ipv4.tcp_keepalive_time = 5' >> /etc/sysctl.conf
	else
		sed -i 's/net.ipv4.tcp_keepalive_time\s\s*/net.ipv4.tcp_keepalive_time = 5/' /etc/sysctl.conf
	fi

	grep '^net.ipv4.tcp_keepalive_time' /etc/sysctl.conf
	is_keepalive_present=$?
	if [ $is_keepalive_present != 0 ]; then
		echo 'net.ipv4.tcp_keepalive_time = 5' >> /etc/sysctl.conf
	else
		sed -i 's/net.ipv4.tcp_keepalive_time\s\s*/net.ipv4.tcp_keepalive_time = 5/' /etc/sysctl.conf
	fi

	grep '^net.ipv4.tcp_keepalive_probes' /etc/sysctl.conf
	is_probes_present=$?
	if [ $is_probes_present != 0 ]; then
		echo 'net.ipv4.tcp_keepalive_probes = 5' >> /etc/sysctl.conf
	else
		sed -i 's/net.ipv4.tcp_keepalive_probes\s\s*/net.ipv4.tcp_keepalive_probes = 5/' /etc/sysctl.conf
	fi


	grep '^net.ipv4.tcp_keepalive_intvl' /etc/sysctl.conf
	is_intvl_present=$?
	if [ $is_intvl_present != 0 ]; then
		echo 'net.ipv4.tcp_keepalive_intvl = 1' >> /etc/sysctl.conf
	else
		sed -i 's/net.ipv4.tcp_keepalive_intvl\s\s*/net.ipv4.tcp_keepalive_intvl = 1/' /etc/sysctl.conf
	fi

fi
