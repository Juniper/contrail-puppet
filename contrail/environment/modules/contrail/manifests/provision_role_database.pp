class contrail::provision_role_database (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $database_ip_list_for_shell,
    $database_name_list_for_shell,
    $config_ip,
    $keystone_admin_user,
    $keystone_admin_password,
    $keystone_admin_tenant
) {
    exec { 'provision-role-database' :
            command   => "python /opt/contrail/provision_role.py ${database_ip_list_for_shell} ${database_name_list_for_shell} ${config_ip} ${keystone_admin_user} ${keystone_admin_password} ${keystone_admin_tenant} 'database' && echo provision-role-database- >> /etc/contrail/contrail_config_exec.out",
            provider  => shell,
            logoutput => $contrail_logoutput
    }
    ->
    notify { "executed provision_role_database":; }
}


