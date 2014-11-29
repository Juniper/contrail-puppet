# The puppet module to set up a Contrail WebUI server
class openstack::profile::contrail::haproxy inherits openstack::profile::haproxy {
    $contrail_control_name_list = $::contrail::config::control_name_list
    $contrail_control_ip_list = $::contrail::config::control_ip_list
    haproxy::listen { 'contrail-api':
        ipaddress        => '0.0.0.0',
        ports            => '8082',
        mode             => 'http',
        options   => {}
    }
    #TODO(nati) support mulitple workers
    haproxy::balancermember { 'contrail-api-member':
        listening_service => 'contrail-api',
        ports             => '9100',
        ipaddresses       => $contrail_control_ip_list,
        server_names      => $contrail_control_name_list,
        options           => 'check',
    }

    haproxy::listen { 'contrail-discovery':
        collect_exported => true,
        ipaddress        => '0.0.0.0',
        ports            => '5998',
        mode             => 'http',
        options   => {}
    }
    #TODO(nati) support mulitple workers
    haproxy::balancermember { 'contrail-discovery-member':
        listening_service => 'contrail-discovery',
        ports             => '9110',
        server_names      => $contrail_control_name_list,
        ipaddresses       => $contrail_control_ip_list,
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

    #TODO(nati) support mulitple workers
    haproxy::balancermember { 'rabbitmq-member':
        listening_service => 'rabbitmq',
        ports             => '5672',
        server_names      => $contrail_control_name_list,
        ipaddresses       => $contrail_control_ip_list,
        options           => 'check',
    }
}
