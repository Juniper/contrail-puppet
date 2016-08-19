class contrail::compute::cp_ifcfg_file (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    exec { 'cp-ifcfg-file' :
            command   => 'cp -f /etc/contrail/ifcfg-* /etc/sysconfig/network-scripts && echo cp-ifcfg-file >> /etc/contrail/contrail_compute_exec.out',
            unless    => 'grep -qx cp-ifcfg-file /etc/contrail/contrail_compute_exec.out',
            provider  => 'shell',
            logoutput => $contrail_logoutput
    }
    ->
    Reboot['compute']
    ->
    notify { "executed cp_ifcfg_file" :; }
}
