class contrail::delete_conductor (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $conductor_idx
) {
    exec { "delete_conductor":
        command => "/bin/bash -c \"source /etc/contrail/openstackrc && nova service-delete ${conductor_idx}\" && echo delete_conductor >> /etc/contrail/contrail_openstack_exec.out",
        unless => "grep -qx delete_conductor /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => $contrail_logoutput
    }
    ->
    notify { "executed delete_conductor" :; }
}

