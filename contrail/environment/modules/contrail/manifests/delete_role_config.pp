class contrail::delete_role_config (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $config_ip_to_use,
    $hostname,
    $host_control_ip,
    $multi_tenancy_options
) {
    exec { "provision-role-config-del" :
	command => "python /usr/share/contrail-utils/provision_config_node.py --api_server_ip $config_ip_to_use --host_name $hostname --host_ip $host_control_ip  --oper del $multi_tenancy_options && echo provision-role-config-del >> /etc/contrail/contrail_config_exec.out",
	provider => shell,
	logoutput => $contrail_logoutput
    }
    ->
    notify { "executed delete_role_config" :; }
}

