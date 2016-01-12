class contrail::provision_role_collector (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $collector_ip_list_for_shell,
    $collector_name_list_for_shell,
    $config_ip,
    $keystone_admin_user,
    $keystone_admin_password,
    $keystone_admin_tenant
) {
    exec { 'provision-role-collector' :
            command   => "python /opt/contrail/provision_role.py ${collector_ip_list_for_shell} ${collector_name_list_for_shell} ${config_ip} ${keystone_admin_user} ${keystone_admin_password} ${keystone_admin_tenant} 'collector' && echo provision-role-collector >> /etc/contrail/contrail_config_exec.out",
            provider  => shell,
            logoutput => $contrail_logoutput
    }
    ->
    notify { "executed provision_role_collector":; }
}

