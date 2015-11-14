class contrail::config::rabbitmq (
    $host_control_ip = $::contrail::params::host_ip,
    $control_ip_list = $::contrail::params::control_ip_list,
    $haproxy = $::contrail::params::haproxy,
    $openstack_manage_amqp = $::contrail::params::openstack_manage_amqp,
    $amqp_server_ip = $::contrail::params::amqp_server_ip,
    $config_ip_list = $::contrail::params::config_ip_list,
    $config_name_list = $::contrail::params::config_name_list,
    $config_ip = $::contrail::params::config_ip_to_use,
    $collector_ip = $::contrail::params::collector_ip_to_use,
    $contrail_rabbit_servers= $::contrail::params::contrail_rabbit_servers,
    $contrail_rabbit_port= $::contrail::params::contrail_rabbit_port,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $amqp_ip_list = $::contrail::params::amqp_ip_list,
) {
    # Check to see if amqp_ip_list was passed by user. If yes, rabbitmq provisioning can be skipped
    if (! $amqp_ip_list) {
	    # Set number of config nodes
	    $cfgm_number = size($config_ip_list)
	    if ($cfgm_number == 1) {
		$rabbitmq_conf_template = 'rabbitmq_config_single_node.erb'
	    } else {
		$rabbitmq_conf_template = 'rabbitmq_config.erb'
	    }

	    if ( $host_control_ip == $config_ip_list[0]) {
		$master = 'yes'
	    } else {
		$master = 'no'
	    }

	    $cfgm_ip_list_shell = inline_template('<%= @config_ip_list.map{ |ip| "#{ip}" }.join(",") %>')
	    $cfgm_name_list_shell = inline_template('<%= @config_name_list.map{ |ip| "#{ip}" }.join(",") %>')
	    $rabbit_env = "NODE_IP_ADDRESS=${host_control_ip}\nNODENAME=rabbit@${::hostname}ctl\n"

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
	    file { '/etc/contrail/add_etc_host.py' :
		mode   => '0755',
		group  => root,
		source => "puppet:///modules/${module_name}/add_etc_host.py"
	    }
	    ->
	    exec { 'add-etc-hosts' :
		command   => "python /etc/contrail/add_etc_host.py ${cfgm_ip_list_shell} ${cfgm_name_list_shell} && echo add-etc-hosts >> /etc/contrail/contrail_config_exec.out",
		unless    => 'grep -qx add-etc-hosts /etc/contrail/contrail_config_exec.out',
		provider  => shell,
		logoutput => $contrail_logoutput
	    }
	    ->
	    file { '/etc/contrail/form_rmq_cluster.sh' :
		mode   => '0755',
		group  => root,
		source => "puppet:///modules/${module_name}/form_rmq_cluster.sh"
	    } ->
	    exec { 'verify-rabbitmq' :
		command   => "/etc/contrail/form_rmq_cluster.sh ${master} ${host_control_ip} ${config_ip_list} & echo verify-rabbitmq >> /etc/contrail/contrail_config_exec.out",
		unless    => 'grep -qx verify-rabbitmq /etc/contrail/contrail_config_exec.out',
		provider  => shell,
		logoutput => $contrail_logoutput
	    }
    }

}
