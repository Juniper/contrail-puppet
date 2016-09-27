class contrail::provision_alarm (
    $contrail_logoutput      = $::contrail::params::contrail_logoutput,
    $keystone_admin_user     = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $config_ip_to_use        = $::contrail::params::config_ip_to_use,
    $keystone_admin_tenant   = $::contrail::params::keystone_admin_tenant,
) {
    exec { 'provision-alarm' :
            command   => "python /opt/contrail/utils/provision_alarm.py \
                       --api_server_ip ${config_ip_to_use} \
                       --api_server_port 8082 \
                       --admin_tenant_name ${keystone_admin_tenant} \
                       --admin_user \"${keystone_admin_user}\" \
                       --admin_password \"${keystone_admin_password}\" \
                       && echo provision-alarm >> /etc/contrail/contrail_config_exec.out",
            unless    => 'grep -qx provision-alarm /etc/contrail/contrail_config_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput,
    }
}
