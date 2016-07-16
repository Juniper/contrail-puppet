class contrail::rabbitmq (
    $host_control_ip = $::contrail::params::host_ip,
    $control_ip_list = $::contrail::params::control_ip_list,
    $haproxy = $::contrail::params::haproxy,
    $openstack_manage_amqp = $::contrail::params::openstack_manage_amqp,
    $amqp_server_ip = $::contrail::params::amqp_server_ip,
    $config_ip_list = $::contrail::params::config_ip_list,
    $openstack_ip_list = $::contrail::params::openstack_ip_list,
    $config_name_list = $::contrail::params::config_name_list,
    $openstack_name_list = $::contrail::params::openstack_name_list,
    $config_ip = $::contrail::params::config_ip_to_use,
    $collector_ip = $::contrail::params::collector_ip_to_use,
    $contrail_rabbit_servers= $::contrail::params::contrail_rabbit_servers,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $contrail_amqp_ip_list = $::contrail::params::contrail_amqp_ip_list,
    $uuid = $::contrail::params::uuid,
) {
    # Check to see if amqp_ip_list was passed by user. If yes, rabbitmq provisioning can be skipped
    if (!$contrail_amqp_ip_list or ($openstack_manage_amqp and ($host_control_ip in $openstack_ip_list)) ) {
        if ($openstack_manage_amqp and ($host_control_ip in $openstack_ip_list)) {
            $amqp_ip_list = $openstack_ip_list
            $amqp_name_list = $openstack_name_list
        }
        else {
            $amqp_ip_list = $config_ip_list
            $amqp_name_list = $config_name_list
        }
	# Set number of amqp nodes
	$amqp_number = size($amqp_ip_list)
	if ($amqp_number == 1) {
	    $rabbitmq_conf_template = 'rabbitmq_config_single_node.erb'
	} else {
	    $rabbitmq_conf_template = 'rabbitmq_config.erb'
	}

        if ( $host_control_ip == $amqp_ip_list[0]) {
	    $master = 'yes'
	} else {
	    $master = 'no'
	}

        $amqp_ip_list_shell = join($amqp_ip_list,",")
        $amqp_name_list_shell = join($amqp_name_list, ",")
        $rabbit_env = "NODE_IP_ADDRESS=${host_control_ip}\nNODENAME=rabbit@${::hostname}ctl\n"

        if !defined(Service['rabbitmq-server']) {
            service { 'rabbitmq-server':
                ensure => running,
                enable => true
            }
        }

        # Handle rabbitmq.config changes
        file {'/var/lib/rabbitmq/.erlang.cookie':
            mode    => '0400',
            owner   => rabbitmq,
            group   => rabbitmq,
            content => $uuid
        }->
        file { '/etc/rabbitmq/rabbitmq.config' :
            content => template("${module_name}/${rabbitmq_conf_template}"),
        }
        ->
        file { '/etc/rabbitmq/rabbitmq-env.conf' :
            mode    => '0755',
            group   => root,
            content => $rabbit_env,
        }
        ->
        class {'::contrail::add_etc_hosts':
            amqp_ip_list_shell => $amqp_ip_list_shell,
            amqp_name_list_shell => $amqp_name_list_shell
        } ->
        class {'::contrail::verify_rabbitmq':
            master => $master,
            host_control_ip => $host_control_ip,
            amqp_ip_list => $amqp_ip_list
        } ->
        # bringup rabbit only after interface is up, 
        # otherwise rabbit fails to start in centos after reboot
        if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
            Class['::contrail::verify_rabbitmq'] ->
            class { '::contrail::monitor_interface' : }
        }
        contain ::contrail::verify_rabbitmq
        contain ::contrail::add_etc_hosts
    }
}

