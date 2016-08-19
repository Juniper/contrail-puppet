class contrail::delete_role_collector (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $config_ip,
    $hostname,
    $host_control_ip,
    $multi_tenancy_options
) {
    exec { "provision-role-collector-del" :
	command => "python /usr/share/contrail-utils/provision_analytics_node.py --api_server_ip $config_ip --host_name $hostname --host_ip $host_control_ip  --oper del $multi_tenancy_options && echo provision-role-collector-del >> /etc/contrail/contrail_collector_exec.out",
	provider => shell,
	logoutput => $contrail_logoutput
    }
    ->
    notify { "executed delete_role_collector" :; }
}

