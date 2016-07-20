class contrail::config::service(
    $vip = $::contrail::params::vip_to_use,
) {
    service { 'supervisor-config':
        ensure  => running,
        enable  => true,
    }
    if ($::operatingsystem == 'Ubuntu') {
        service { 'supervisor-support-service':
            ensure  => running,
            enable => true,
        }
    }
    #Set rabbit params for both internal and contrail_internal_vip
    if($vip != '') {
        if ($::operatingsystem == 'Ubuntu') {
            Service['supervisor-support-service'] -> Exec['rabbit_os_fix']
        }
        exec { 'rabbit_os_fix':
            command   => "rabbitmqctl set_policy HA-all \"\" '{\"ha-mode\":\"all\",\"ha-sync-mode\":\"automatic\"}' && echo rabbit_os_fix >> /etc/contrail/contrail_openstack_exec.out",
            unless    => 'grep -qx rabbit_os_fix /etc/contrail/contrail_openstack_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput,
            tries     => 3,
            try_sleep => 15,
        }
    }
}
