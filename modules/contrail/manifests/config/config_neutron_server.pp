class contrail::config::config_neutron_server (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    exec { 'config-neutron-server' :
            command   => "service neutron-server restart && echo config-neutron-server >> /etc/contrail/contrail_config_exec.out",
            onlyif    => 'test -f /etc/default/neutron-server',
            unless    => 'grep -qx config-neutron-server /etc/contrail/contrail_config_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
    }
    ->
    notify { "executed config-neutron-server":; }
}
