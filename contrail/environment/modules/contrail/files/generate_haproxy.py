#!/usr/bin/python
#
# Copyright (c) 2013 Juniper Networks, Inc. All rights reserved.
#
import string
import sys 

haproxy_template = string.Template("""

global
        maxconn 10000
        spread-checks 4
        tune.maxrewrite 1024
        tune.bufsize 16384
	log /dev/log	local0
	log /dev/log	local1 notice
	chroot /var/lib/haproxy
	stats socket /run/haproxy/admin.sock mode 660 level admin
	stats timeout 30s
	user haproxy
	group haproxy
	daemon

	# Default SSL material locations
	ca-base /etc/ssl/certs
	crt-base /etc/ssl/private

	# Default ciphers to use on SSL-enabled listening sockets.
	# For more information, see ciphers(1SSL).
	ssl-default-bind-ciphers kEECDH+aRSA+AES:kRSA+AES:+AES256:RC4-SHA:!kEDH:!LOW:!EXP:!MD5:!aNULL:!eNULL

defaults
	log	global
	mode	http
	option                  tcplog
	option	dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
	errorfile 400 /etc/haproxy/errors/400.http
	errorfile 403 /etc/haproxy/errors/403.http
	errorfile 408 /etc/haproxy/errors/408.http
	errorfile 500 /etc/haproxy/errors/500.http
	errorfile 502 /etc/haproxy/errors/502.http
	errorfile 503 /etc/haproxy/errors/503.http
	errorfile 504 /etc/haproxy/errors/504.http
#contrail-collector-marker-start
$__collector_ha_proxy
#contrail-collector-marker-end

#contrail-openstack-marker-start
$__openstack_ha_proxy
#contrail-openstack-marker-end

#contrail-config-marker-start
$__config_ha_proxy
#contrail-config-marker-end


""")

collector_ha_template = string.Template("""#contrail-collector-marker-start
listen contrail-collector-stats :5938
   mode http
   stats enable
   stats uri /
   stats auth $__contrail_hap_user__:$__contrail_hap_passwd__

frontend  contrail-analytics-api *:8081
    default_backend    contrail-analytics-api

backend contrail-analytics-api
    option nolinger
    balance     roundrobin
    option tcp-check
    tcp-check connect port 6379
    default-server error-limit 1 on-error mark-down
$__contrail_analytics_api_backend_servers__

#contrail-collector-marker-end
""")

openstack_ha_template = string.Template("""#contrail-openstack-marker-start
listen contrail-openstack-stats :5936
   mode http
   stats enable
   stats uri /
   stats auth $__contrail_hap_user__:$__contrail_hap_passwd__

frontend openstack-keystone *:5000
    default_backend    keystone-backend

backend keystone-backend
    option tcpka
    option nolinger
    timeout server 24h
    balance roundrobin

    option tcp-check
    tcp-check connect port 3306
    default-server error-limit 1 on-error mark-down

    option tcp-check
    option httpchk
    tcp-check connect port 3337
    tcp-check send Host:localhost
    http-check expect ! rstatus ^5
    default-server error-limit 1 on-error mark-down

    option tcp-check
    tcp-check connect port 6000
    default-server error-limit 1 on-error mark-down

$__keystone_backend_servers__

frontend openstack-keystone-admin *:35357
    default_backend    keystone-admin-backend

backend keystone-admin-backend
    option tcpka
    option nolinger
    timeout server 24h
    balance    roundrobin

    option tcp-check
    tcp-check connect port 3306
    default-server error-limit 1 on-error mark-down

    option tcp-check
    option httpchk
    tcp-check connect port 3337
    tcp-check send Host:localhost
    http-check expect ! rstatus ^5
    default-server error-limit 1 on-error mark-down

    option tcp-check
    tcp-check connect port 35358
    default-server error-limit 1 on-error mark-down

$__keystone_admin_backend_servers__

frontend openstack-glance *:9292
    default_backend    glance-backend

backend glance-backend
    option tcpka
    option nolinger
    timeout server 24h
    balance   roundrobin

    option tcp-check
    tcp-check connect port 3306
    default-server error-limit 1 on-error mark-down

    option tcp-check
    option httpchk
    tcp-check connect port 3337
    tcp-check send Host:localhost
    http-check expect ! rstatus ^5
    default-server error-limit 1 on-error mark-down

    option tcp-check
    tcp-check connect port 9393
    default-server error-limit 1 on-error mark-down
$__glance_backend_servers__

frontend openstack-cinder *:8776
    default_backend  cinder-backend

backend cinder-backend
    option tcpka
    option nolinger
    timeout server 24h
    balance   roundrobin
$__cinder_backend_servers__

frontend ceph-rest-api-server *:5005
    default_backend  ceph-rest-api-server-backend

backend ceph-rest-api-server-backend
    option tcpka
    option nolinger
    timeout server 24h
    balance   roundrobin
$__ceph_restapi_backend_servers__


frontend openstack-nova-api *:8774
    default_backend  nova-api-backend

backend nova-api-backend
    option tcpka
    option nolinger
    timeout server 24h
    balance   roundrobin

    option tcp-check
    tcp-check connect port 3306
    default-server error-limit 1 on-error mark-down

    option tcp-check
    option httpchk
    tcp-check connect port 3337
    tcp-check send Host:localhost
    http-check expect ! rstatus ^5
    default-server error-limit 1 on-error mark-down

    option tcp-check
    tcp-check connect port 9774
    default-server error-limit 1 on-error mark-down

$__nova_api_backend_servers__

frontend openstack-nova-meta *:8775
    default_backend  nova-meta-backend

backend nova-meta-backend
    option tcpka
    option nolinger
    timeout server 24h
    balance   roundrobin

    option tcp-check
    tcp-check connect port 3306
    default-server error-limit 1 on-error mark-down

    option tcp-check
    option httpchk
    tcp-check connect port 3337
    tcp-check send Host:localhost
    http-check expect ! rstatus ^5
    default-server error-limit 1 on-error mark-down

    option tcp-check
    tcp-check connect port 9775
    default-server error-limit 1 on-error mark-down

$__nova_meta_backend_servers__

frontend openstack-nova-vnc *:6080
    default_backend  nova-vnc-backend

backend nova-vnc-backend
    option tcpka
    option nolinger
    timeout server 5h
    balance  roundrobin
    $__nova_vnc_backend_servers__

frontend heat-cfn *:8000
    default_backend heat-cfn-api-backend

frontend heat-srv *:8004
    default_backend heat-api-backend

backend heat-api-backend
    option tcpka
    option nolinger
    timeout server 24h
    balance   roundrobin

    option tcp-check
    tcp-check connect port 3306
    default-server error-limit 1 on-error mark-down

    option tcp-check
    option httpchk
    tcp-check connect port 3337
    tcp-check send Host:localhost
    http-check expect ! rstatus ^5
    default-server error-limit 1 on-error mark-down

    option tcp-check
    tcp-check connect port 8005
$__heat_api_backend_servers__

backend heat-cfn-api-backend
    option tcpka
    option nolinger
    timeout server 24h
    balance   roundrobin

    option tcp-check
    tcp-check connect port 3306
    default-server error-limit 1 on-error mark-down

    option tcp-check
    option httpchk
    tcp-check connect port 3337
    tcp-check send Host:localhost
    http-check expect ! rstatus ^5
    default-server error-limit 1 on-error mark-down

    option tcp-check
    tcp-check connect port 8001
$__heat_cfn_api_backend_servers__

listen memcached 0.0.0.0:11222
   mode tcp
   balance roundrobin
   option tcplog
   maxconn 10000                                                                                   
   balance roundrobin                                                                              
   option tcpka                                                                                    
   option nolinger                                                                                 
   timeout connect 5s                                                                              
   timeout client 0
   timeout server 0
$__memcached_servers__

listen  rabbitmq 0.0.0.0:5673
    mode tcp
    maxconn 10000
    balance leastconn
    option tcpka
    option nolinger
    option forceclose
    timeout client 0
    timeout server 0
    timeout client-fin 60s
    timeout server-fin 60s
$__rabbitmq_servers__

listen  mysql 0.0.0.0:33306
    mode tcp
    balance leastconn
    option tcpka
    option nolinger
    option forceclose
    maxconn 10000
    timeout connect 30s
    timeout client 0
    timeout server 0
    timeout client-fin 60s
    timeout server-fin 60s
$__mysql_servers__

#contrail-openstack-marker-end
""")

config_ha_template = string.Template("""
#contrail-config-marker-start
listen contrail-config-stats :5937
   mode http
   stats enable
   stats uri /
   stats auth $__contrail_hap_user__:$__contrail_hap_passwd__

frontend quantum-server *:9696
    default_backend    quantum-server-backend

frontend  contrail-api *:8082
    default_backend    contrail-api-backend

frontend  contrail-discovery *:5998
    default_backend    contrail-discovery-backend

backend quantum-server-backend
    option nolinger
    balance     roundrobin
$__contrail_quantum_servers__
    #server  10.84.14.2 10.84.14.2:9697 check

backend contrail-api-backend
    option nolinger
    balance     roundrobin
$__contrail_api_backend_servers__
    #server  10.84.14.2 10.84.14.2:9100 check
    #server  10.84.14.2 10.84.14.2:9101 check

backend contrail-discovery-backend
    option nolinger
    balance     roundrobin
$__contrail_disc_backend_servers__
    #server  10.84.14.2 10.84.14.2:9110 check
    #server  10.84.14.2 10.84.14.2:9111 check

$__rabbitmq_config__
#contrail-config-marker-end
""")



def main(args_str=None):
    config_stanza = ""
    collector_stanza = ""
    openstack_stanza = ""

    host_ip = sys.argv[1]
    internal_vip = sys.argv[2]
    contrail_internal_vip = sys.argv[3]
    
    config_host_list_str = sys.argv[4]
    config_ip_list_str = sys.argv[5]

    openstack_host_list_str = sys.argv[6]
    openstack_ip_list_str = sys.argv[7]

    collector_host_list_str = sys.argv[8]
    collector_ip_list_str = sys.argv[9]

    config_host_list = config_host_list_str.split(",")
    config_ip_list = config_ip_list_str.split(",")

    openstack_host_list = openstack_host_list_str.split(",")
    openstack_ip_list = openstack_ip_list_str.split(",")

    collector_host_list = collector_host_list_str.split(",")
    collector_ip_list = collector_ip_list_str.split(",")


    if host_ip in config_ip_list:
        config_stanza = generate_config_ha_config(config_ip_list, openstack_ip_list, host_ip, internal_vip, contrail_internal_vip)

    if host_ip in config_ip_list and (internal_vip != "none" or contrail_internal_vip != "none"):
        collector_stanza = generate_collector_ha_config(collector_ip_list, host_ip)

    if (internal_vip != "none") and (host_ip in openstack_ip_list):
        openstack_stanza = generate_openstack_ha_config(openstack_ip_list, host_ip)

    haproxy_config = haproxy_template.safe_substitute({
        '__collector_ha_proxy' : collector_stanza,
        '__config_ha_proxy' : config_stanza,
        '__openstack_ha_proxy' : openstack_stanza,
        })

    cfg_file = open('/etc/haproxy/haproxy.cfg', 'w+')
    cfg_file.write(haproxy_config)
    cfg_file.close()


def generate_collector_ha_config(collector_ip_list, mgmt_host_ip):
    contrail_analytics_api_server_lines = ''
    space = ' ' * 3

    for server_index, host_ip in enumerate(collector_ip_list):
#        server_index = env.roledefs['collector'].index(host_string) + 1
#        mgmt_host_ip = hstr_to_ip(host_string)
#        host_ip = hstr_to_ip(get_control_host_string(host_string))
        contrail_analytics_api_server_lines +=\
            '%s server %s %s:9081 check inter 2000 rise 2 fall 3\n'\
             % (space, host_ip, host_ip)

#    for host_string in env.roledefs['collector']:
    haproxy_config = collector_ha_template.safe_substitute({
	'__contrail_analytics_api_backend_servers__' : contrail_analytics_api_server_lines,
	'__contrail_hap_user__': 'haproxy',
	'__contrail_hap_passwd__': 'contrail123',
	})
    return haproxy_config

def generate_config_ha_config(config_ip_list, openstack_ip_list, mgmt_ip, internal_vip, contrail_internal_vip):
    q_listen_port = 9697
    q_server_lines = ''
    api_listen_port = 9100
    api_server_lines = ''
    disc_listen_port = 9110
    disc_server_lines = ''
    nworkers = 1
    rabbitmq_config = """
listen  rabbitmq 0.0.0.0:5673
    mode tcp
    maxconn 10000
    balance roundrobin
    option tcpka
    option redispatch
    timeout client 48h
    timeout server 48h\n"""
    space = ' ' * 3
    for server_index, host_ip in enumerate(config_ip_list):
#        server_index = env.roledefs['cfgm'].index(host_string) + 1
#        host_ip = hstr_to_ip(get_control_host_string(host_string))
        q_server_lines = q_server_lines + \
        '    server %s %s:%s check inter 2000 rise 2 fall 3\n' \
                    %(host_ip, host_ip, str(q_listen_port))
        for i in range(nworkers):
            api_server_lines = api_server_lines + \
            '    server %s %s:%s check inter 2000 rise 2 fall 3\n' \
                        %(host_ip, host_ip, str(api_listen_port + i))
            disc_server_lines = disc_server_lines + \
            '    server %s %s:%s check inter 2000 rise 2 fall 3\n' \
                        %(host_ip, host_ip, str(disc_listen_port + i))
        rabbitmq_config +=\
            '%s server rabbit%s %s:5672 check inter 2000 rise 2 fall 3 weight 1 maxconn 500\n'\
             % (space, server_index, host_ip)

    if ( mgmt_ip in openstack_ip_list and internal_vip != "none" ) or \
        contrail_internal_vip == "none" :
        # Openstack and cfgm are same nodes.
        # Dont add rabbitmq confing twice in haproxy, as setup_ha has added already.
        rabbitmq_config = ''

    haproxy_config = config_ha_template.safe_substitute({
	'__contrail_quantum_servers__': q_server_lines,
	'__contrail_api_backend_servers__': api_server_lines,
	'__contrail_disc_backend_servers__': disc_server_lines,
	'__contrail_hap_user__': 'haproxy',
	'__contrail_hap_passwd__': 'contrail123',
	'__rabbitmq_config__': rabbitmq_config,
        })

    return haproxy_config

def generate_openstack_ha_config(openstack_ip_list, mgmt_host_ip):

    keystone_server_lines = ''
    keystone_admin_server_lines = ''
    glance_server_lines = ''
    cinder_server_lines = ''
    ceph_restapi_server_lines = ''
    nova_api_server_lines = ''
    nova_meta_server_lines = ''
    nova_vnc_server_lines = ''
    heat_api_server_lines= ''
    heat_cfn_api_server_lines = ''
    memcached_server_lines = ''
    rabbitmq_server_lines = ''
    mysql_server_lines = ''
    space = ' ' * 3

    for server_index, host_ip in enumerate(openstack_ip_list):
#        server_index = env.roledefs['openstack'].index(host_string) + 1
#        mgmt_host_ip = hstr_to_ip(host_string)
#        host_ip = hstr_to_ip(get_control_host_string(host_string))
        keystone_server_lines +=\
            '%s server %s %s:6000 check inter 2000 rise 2 fall 1\n'\
             % (space, host_ip, host_ip)
        keystone_admin_server_lines +=\
            '%s server %s %s:35358 check inter 2000 rise 2 fall 1\n'\
             % (space, host_ip, host_ip)
        glance_server_lines +=\
            '%s server %s %s:9393 check inter 2000 rise 2 fall 1\n'\
             % (space, host_ip, host_ip)
        cinder_server_lines +=\
            '%s server %s %s:9776 check inter 2000 rise 2 fall 3\n'\
             % (space, host_ip, host_ip)
        ceph_restapi_server_lines +=\
            '%s server %s %s:5006 check inter 2000 rise 2 fall 3\n'\
             % (space, host_ip, host_ip)
        nova_api_server_lines +=\
            '%s server %s %s:9774 check inter 2000 rise 2 fall 1\n'\
             % (space, host_ip, host_ip)
        nova_meta_server_lines +=\
            '%s server %s %s:9775 check inter 2000 rise 2 fall 1\n'\
             % (space, host_ip, host_ip)
        nova_vnc_server_lines  +=\
            '%s server %s %s:6999 check inter 2000 rise 2 fall 3\n'\
             % (space, host_ip, host_ip)
        heat_api_server_lines  +=\
            '%s server %s %s:8005 check inter 2000 rise 2 fall 1\n'\
             % (space, host_ip, host_ip)
        heat_cfn_api_server_lines  +=\
            '%s server %s %s:8001 check inter 2000 rise 2 fall 1\n'\
             % (space, host_ip, host_ip)
        if server_index <= 1:
            memcached_server_lines +=\
                '%s server repcache%s %s:11211 check inter 2000 rise 2 fall 3\n'\
                 % (space, server_index, host_ip)
        if server_index == 0:
            rabbitmq_server_lines +=\
                '%s server rabbit%s %s:5672 weight 200 check inter 2000 rise 2 fall 3\n'\
                 % (space, server_index, host_ip)
        else:
            rabbitmq_server_lines +=\
                '%s server rabbit%s %s:5672 weight 100 check inter 2000 rise 2 fall 3 backup\n'\
                 % (space, server_index, host_ip)
        if server_index == 0:
             mysql_server_lines +=\
                   '%s server mysql%s %s:3306 weight 200 check inter 2000 rise 2 fall 3\n'\
                   % (space, server_index, host_ip)
        else:
             mysql_server_lines +=\
                   '%s server mysql%s %s:3306 weight 100 check inter 2000 rise 2 fall 3 backup\n'\
                   % (space, server_index, host_ip)


    haproxy_config = openstack_ha_template.safe_substitute({
	'__keystone_backend_servers__' : keystone_server_lines,
	'__keystone_admin_backend_servers__' : keystone_admin_server_lines,
	'__glance_backend_servers__' : glance_server_lines,
	'__cinder_backend_servers__' : cinder_server_lines,
	'__ceph_restapi_backend_servers__' : ceph_restapi_server_lines,
	'__nova_api_backend_servers__' : nova_api_server_lines,
	'__nova_meta_backend_servers__' : nova_meta_server_lines,
	'__nova_vnc_backend_servers__' : nova_vnc_server_lines,
	'__heat_api_backend_servers__': heat_api_server_lines,
	'__heat_cfn_api_backend_servers__': heat_cfn_api_server_lines,
	'__memcached_servers__' : memcached_server_lines,
	'__rabbitmq_servers__' : rabbitmq_server_lines,
	'__mysql_servers__' : mysql_server_lines,
	'__contrail_hap_user__': 'haproxy',
	'__contrail_hap_passwd__': 'contrail123',
	})
    
    return haproxy_config

if __name__ == "__main__":
    main(sys.argv[1:])

