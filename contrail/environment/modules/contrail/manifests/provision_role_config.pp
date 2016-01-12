class contrail::provision_role_config (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $config_ip_list_for_shell,
    $config_name_list_for_shell,
    $config_ip,
    $keystone_admin_user,
    $keystone_admin_password,
    $keystone_admin_tenant
) {
    exec { 'provision-role-config' :
            command   => "python /opt/contrail/provision_role.py ${config_ip_list_for_shell} ${config_name_list_for_shell} ${config_ip} ${keystone_admin_user} ${keystone_admin_password} ${keystone_admin_tenant} 'config' && echo provision-role-config >> /etc/contrail/contrail_config_exec.out",
            provider  => shell,
            logoutput => $contrail_logoutput
    }
    ->
    notify { "executed provision_role_config":; }
}

