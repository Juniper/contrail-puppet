class contrail::provision_role_collector (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $collector_ip_list_for_shell = $::contrail::provision_contrail::collector_ip_list_for_shell,
    $collector_name_list_for_shell = $::contrail::provision_contrail::collector_name_list_for_shell,
    $config_ip = $::contrail::params::config_ip_list[0],
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
) {
    exec { 'provision-role-collector' :
            command   => "python /opt/contrail/provision_role.py ${collector_ip_list_for_shell} ${collector_name_list_for_shell} ${config_ip} ${keystone_admin_user} ${keystone_admin_password} ${keystone_admin_tenant} 'collector' && echo provision-role-collector >> /etc/contrail/contrail_config_exec.out",
            provider  => shell,
            logoutput => $contrail_logoutput
    }
    ->
    notify { "executed provision_role_collector":; }
}

