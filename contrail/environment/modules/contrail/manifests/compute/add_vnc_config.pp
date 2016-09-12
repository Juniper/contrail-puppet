class contrail::compute::add_vnc_config (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $host_control_ip,
    $config_ip_to_use,
    $keystone_admin_user,
    $keystone_admin_password,
    $keystone_admin_tenant,
    $openstack_ip,
    $enable_dpdk
) {
    if ($enable_dpdk){
       $enable_dpdk_str = "--dpdk_enabled"
    } else {
       $enable_dpdk_str = ""
    }

    file { '/opt/contrail/utils/provision_vrouter.py':
            ensure => present,
            mode   => '0755',
            owner  => root,
            group  => root
    }
    ->
    exec { 'add-vnc-config' :
            command   => "/bin/bash -c \"python /opt/contrail/utils/provision_vrouter.py --host_name ${::hostname} --host_ip ${host_control_ip} --api_server_ip ${config_ip_to_use} --oper add --admin_user ${keystone_admin_user} --admin_password ${keystone_admin_password} --admin_tenant_name ${keystone_admin_tenant} --openstack_ip ${openstack_ip} ${enable_dpdk_str} && echo add-vnc-config >> /etc/contrail/contrail_compute_exec.out\"",
            unless    => 'grep -qx add-vnc-config /etc/contrail/contrail_compute_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
    }
}
