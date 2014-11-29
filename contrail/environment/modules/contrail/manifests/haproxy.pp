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
    $config_name_list =  $::contrail::params::config_name_list
) inherits ::haproxy {
    require ::contrail::params
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
}

