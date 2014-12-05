# == Class: contrail::haproxy
#
# This class is used to configure haproxy service on config nodes.
#
# === Parameters:
#
# [*config_ip_list*]
#     List of control interface IP addresses of all the servers running config role.
#
# [*config_name_list*]
#     List of host names of all the servers running config role.
#
# The puppet module to set up a haproxy server
class contrail::haproxy (
    $config_ip_list = $::contrail::params::config_ip_list,
    $config_name_list =  $::contrail::params::config_name_list,
    $openstack_ip_list = $::contrail::params::openstack_ip_list,
    $openstack_name_list =  $::contrail::params::openstack_name_list,
    $collector_ip_list = $::contrail::params::collector_ip_list,
    $collector_name_list =  $::contrail::params::collector_name_list,
    $contrail_internal_vip =  $::contrail::params::contrail_internal_vip,
    $internal_vip =  $::contrail::params::internal_vip,
    $host_ip = $::contrail::params::host_ip
) inherits ::haproxy {
    require ::contrail::params

    # Debug - Print all variables
    notify { "Haproxy - config_ip_list = $config_ip_list":; }
    notify { "Haproxy - config_name_list = $config_name_list":;}
    notify { "Haproxy - openstack_ip_list = $openstack_ip_list":; }
    notify { "Haproxy - openstack_name_list = $openstack_name_list":;}
    notify { "Haproxy - collector_ip_list = $collector_ip_list":; }
    notify { "Haproxy - collector_name_list = $collector_name_list":;}
    notify { "Haproxy - internal_vip = $intenal_vip":; }
    notify { "Haproxy - contrail_internal_vip = $contrail_internal_vip":;}
    notify { "Haproxy - host_ip = $host_ip":;}
    $manage_amqp = "no"


    if ($host_ip in $config_ip_list) {
	notify { "Haproxy - Setting up ha-cfg for config":;}

	haproxy::listen { 'contrail-api':
	    ipaddress        => '0.0.0.0',
	    ports            => '8082',
	    mode             => 'http',
	    options   => {}
	}

	haproxy::balancermember { 'contrail-api-member':
	    listening_service => 'contrail-api',
	    ports             => '9100',
	    ipaddresses       => $config_ip_list,
	    server_names      => $config_name_list,
	    options           => 'check',
	}

	haproxy::listen { 'contrail-discovery':
	    collect_exported => true,
	    ipaddress        => '0.0.0.0',
	    ports            => '5998',
	    mode             => 'http',
	    options   => {}
	}

	haproxy::balancermember { 'contrail-discovery-member':
	    listening_service => 'contrail-discovery',
	    ports             => '9110',
	    ipaddresses       => $config_ip_list,
	    server_names      => $config_name_list,
	    options           => 'check',
	}

	haproxy::listen { 'rabbitmq':
	    collect_exported => true,
	    ipaddress        => '0.0.0.0',
	    ports            => '5673',
	    mode             => 'tcp',
	    options   => {
		option => ['tcpka', 'redispatch', 'nolinger']
	    }
	}

	haproxy::balancermember { 'rabbitmq-member':
	    listening_service => 'rabbitmq',
	    ports             => '5672',
	    ipaddresses       => $config_ip_list,
	    server_names      => $config_name_list,
	    options           => 'check',
	}

	haproxy::listen { 'quantum-server':
	    collect_exported => true,
	    ipaddress        => '0.0.0.0',
	    ports            => '9696',
	    mode             => 'tcp',
	    options   => { }
	}

	haproxy::balancermember { 'quantum-server-member':
	    listening_service => 'quantum-server',
	    ports             => '9697',
	    ipaddresses       => $config_ip_list,
	    server_names      => $config_name_list,
	    options           => 'check',
	}

	#Add collector HA
	if ($contrail_internal_vip != "") {
	    notify { "Haproxy - Setting up ha-cfg for collector":;}

	    haproxy::listen { 'contrail-analyticsapi':
		collect_exported => true,
		ipaddress        => '0.0.0.0',
		ports            => '8081',
		mode             => 'tcp',
		options   => {
		    option => ['nolinger']
		}
	    }

	    haproxy::balancermember { 'contrail-analyticsapi-member':
		listening_service => 'contrail-analyticsapi',
		ports             => '9081',
		ipaddresses       => $collector_ip_list,
		server_names      => $collector_name_list,
		options           => 'check',
	    }
	}

    }

    #Add openstack HA
    if ($host_ip in $openstack_ip_list and $internal_vip != "") {
	notify { "Haproxy - Setting up ha-cfg for openstack-ha":;}

	haproxy::listen { 'openstack-keystone':
	    collect_exported => true,
	    ipaddress        => '0.0.0.0',
	    ports            => '5000',
	    mode             => 'tcp',
	    options   => {
		option => ['tcpka', 'nolinger']
	    }
	}

	haproxy::balancermember { 'openstack-keystone-member':
	    listening_service => 'openstack-keystone',
	    ports             => '6000',
	    ipaddresses       => $openstack_ip_list,
	    server_names      => $openstack_name_list,
	    options           => 'check',
	}

	haproxy::listen { 'openstack-keystoneadmin':
	    collect_exported => true,
	    ipaddress        => '0.0.0.0',
	    ports            => '35357',
	    mode             => 'tcp',
	    options   => {
		option => ['tcpka', 'nolinger']
	    }
	}

	haproxy::balancermember { 'openstack-keystoneadmin-member':
	    listening_service => 'openstack-keystoneadmin',
	    ports             => '35358',
	    ipaddresses       => $openstack_ip_list,
	    server_names      => $openstack_name_list,
	    options           => 'check',
	}
	haproxy::listen { 'openstack-glance':
	    collect_exported => true,
	    ipaddress        => '0.0.0.0',
	    ports            => '9292',
	    mode             => 'tcp',
	    options   => {
		option => ['tcpka', 'nolinger']
	    }
	}
	haproxy::balancermember { 'openstack-glance-member':
	    listening_service => 'openstack-glance',
	    ports             => '9393',
	    ipaddresses       => $openstack_ip_list,
	    server_names      => $openstack_name_list,
	    options           => 'check',
	}

	haproxy::listen { 'openstack-cinder':
	    collect_exported => true,
	    ipaddress        => '0.0.0.0',
	    ports            => '8776',
	    mode             => 'tcp',
	    options   => {
		option => ['tcpka', 'nolinger']
	    }
	}

	haproxy::balancermember { 'openstack-cinder-member':
	    listening_service => 'openstack-cinder',
	    ports             => '9776',
	    ipaddresses       => $openstack_ip_list,
	    server_names      => $openstack_name_list,
	    options           => 'check',
	}

	haproxy::listen { 'openstack-novaapi':
	    collect_exported => true,
	    ipaddress        => '0.0.0.0',
	    ports            => '8774',
	    mode             => 'tcp',
	    options   => {
		option => ['tcpka', 'nolinger']
	    }
	}

	haproxy::balancermember { 'openstack-novaapi-member':
	    listening_service => 'openstack-novaapi',
	    ports             => '9774',
	    ipaddresses       => $openstack_ip_list,
	    server_names      => $openstack_name_list,
	    options           => 'check',
	}

	haproxy::listen { 'openstack-novameta':
	    collect_exported => true,
	    ipaddress        => '0.0.0.0',
	    ports            => '8775',
	    mode             => 'tcp',
	    options   => {
		option => ['tcpka', 'nolinger']
	    }
	}

	haproxy::balancermember { 'openstack-novameta-member':
	    listening_service => 'openstack-novameta',
	    ports             => '9775',
	    ipaddresses       => $openstack_ip_list,
	    server_names      => $openstack_name_list,
	    options           => 'check',
	}

	haproxy::listen { 'memcached':
	    collect_exported => true,
	    ipaddress        => '0.0.0.0',
	    ports            => '11222',
	    mode             => 'tcp',
	    options   => {
		option => ['tcpka', 'nolinger', 'tcplog']
	    }
	}

	haproxy::balancermember { 'memcached-member':
	    listening_service => 'memcached',
	    ports             => '11211',
	    ipaddresses       => $openstack_ip_list,
	    server_names      => $openstack_name_list,
	    options           => 'check',
	}

        #if openstack needs a separate rabbitmq cluster
        if (!($host_ip in $config_ip_list) and ($manage_amqp == "yes")) {
	    haproxy::listen { 'rabbitmq':
		collect_exported => true,
		ipaddress        => '0.0.0.0',
		ports            => '5673',
		mode             => 'tcp',
		options   => {
		    option => ['tcpka', 'redispatch']
		}
	    }

	    haproxy::balancermember { 'rabbitmq-member':
		listening_service => 'rabbitmq',
		ports             => '5672',
		ipaddresses       => $openstack_ip_list,
		server_names      => $openstack_name_list,
		options           => 'check',
	    }
        }

	haproxy::listen { 'mysql':
	    collect_exported => true,
	    ipaddress        => '0.0.0.0',
	    ports            => '33306',
	    mode             => 'tcp',
	    options   => {
		option => ['tcpka', 'nolinger', 'redispatch']
	    }
	}

	haproxy::balancermember { 'mysql-member':
	    listening_service => 'mysql',
	    ports             => '3306',
	    ipaddresses       => $openstack_ip_list,
	    server_names      => $openstack_name_list,
	    options           => 'check',
	}
    }
}

