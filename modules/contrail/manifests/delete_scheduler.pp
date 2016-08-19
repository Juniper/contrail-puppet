class contrail::delete_scheduler (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $scheduler_idx
) {
    exec { "delete_scheduler":
        command => "/bin/bash -c \"source /etc/contrail/openstackrc && nova service-delete ${scheduler_idx}\" && echo delete_scheduler >> /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        unless => "grep -qx delete_scheduler /etc/contrail/contrail_openstack_exec.out",
        logoutput => $contrail_logoutput
    }
    ->
    notify { "executed delete_scheduler" :; }
}

