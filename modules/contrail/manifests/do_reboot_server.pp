class contrail::do_reboot_server (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $reboot_flag,
) {
    exec { 'do-reboot-server' :
                command   => '/sbin/reboot -f now && echo $reboot_flag >> /etc/contrail/contrail_common_exec.out',
                unless    => 'grep -qx $reboot_flag /etc/contrail/contrail_common_exec.out',
                onlyif    => 'grep -qx flag-reboot-server /etc/contrail/contrail_compute_exec.out',
                provider  => shell,
                logoutput => $contrail_logoutput
    }
    ->
    notify { "executed reboot server" :; }
}

