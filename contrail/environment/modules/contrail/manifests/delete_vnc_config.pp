class contrail::delete_vnc_config (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $config_ip_to_use,
    $host_control_ip,
    $keystone_admin_user,
    $keystone_admin_password
) {
    exec { 'del-vnc-config' :
	command => "/bin/bash -c \"python /opt/contrail/utils/provision_vrouter.py --host_name $::hostname --host_ip $host_control_ip --api_server_ip $config_ip_to_use --oper del --admin_user $keystone_admin_user --admin_password $keystone_admin_password --admin_tenant_name $keystone_admin_tenant --openstack_ip $openstack_ip ${contrail_router_type} && echo del-vnc-config >> /etc/contrail/contrail_compute_exec.out\"",
	unless  => 'grep -qx del-vnc-config /etc/contrail/contrail_compute_exec.out',
	provider => shell,
	logoutput => $contrail_logoutput
    }
    ->
    notify { "executed delete_vnc_config" :; }
}

