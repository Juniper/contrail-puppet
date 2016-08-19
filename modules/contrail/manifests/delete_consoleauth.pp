class contrail::delete_consoleauth (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $consoleauth_idx
) {
    exec { "delete_consoleauth":
        command => "/bin/bash -c \"source /etc/contrail/openstackrc && nova service-delete ${consoleauth_idx}\" && echo delete_consoleauth >> /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        unless => "grep -qx delete_consoleauth /etc/contrail/contrail_openstack_exec.out",
        logoutput => $contrail_logoutput
    }
    ->
    notify { "executed delete_consoleauth" :; }
}

