class contrail::exec_disable_mpm_event (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    # Disable mpm_event apache module
    exec { "exec_disable_mpm_event":
          command => "a2dismod mpm_event && service apache2 restart && echo exec_disable_mpm_event>> /etc/contrail/contrail_openstack_exec.out",
          onlyif => "test -f /etc/apache2/mods-enabled/mpm_event.load",
          provider => shell,
          logoutput => $contrail_logoutput
    }
    ->
    notify { "executed exec_disable_mpm_event" :; }
}

