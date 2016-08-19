class contrail::delete_console (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $console_idx
) {
    exec { "delete_console":
        command => "/bin/bash -c \"source /etc/contrail/openstackrc && nova service-delete ${console_idx}\" && echo delete_console >> /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        unless => "grep -qx delete_console /etc/contrail/contrail_openstack_exec.out",
        logoutput => $contrail_logoutput
    }
    ->
    notify { "executed delete_console" :; }
}

