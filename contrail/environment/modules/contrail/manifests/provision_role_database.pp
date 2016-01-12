class contrail::provision_role_database (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $database_ip_list_for_shell = $::contrail::provision_contrail::database_ip_list_for_shell,
    $database_name_list_for_shell = $::contrail::provision_contrail::database_name_list_for_shell,
    $config_ip = $::contrail::params::config_ip_list[0],
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
) {
    exec { 'provision-role-database' :
            command   => "python /opt/contrail/provision_role.py ${database_ip_list_for_shell} ${database_name_list_for_shell} ${config_ip} ${keystone_admin_user} ${keystone_admin_password} ${keystone_admin_tenant} 'database' && echo provision-role-database- >> /etc/contrail/contrail_config_exec.out",
            provider  => shell,
            logoutput => $contrail_logoutput
    }
    ->
    notify { "executed provision_role_database":; }
}


