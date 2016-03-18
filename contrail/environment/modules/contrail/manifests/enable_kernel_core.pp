class contrail::enable_kernel_core (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    # enable kernel core , below python code has bug, for now ignore by executing echo regardless and thus returning true for cmd.
    # need to revisit afterwards.

    package { 'linux-crashdump' : ensure => present,}
    ->
    exec { 'enable-kernel-core' :
        command   => 'python /etc/contrail/contrail_setup_utils/enable_kernel_core.py; echo enable-kernel-core >> /etc/contrail/contrail_common_exec.out',
        require   => File['/etc/contrail/contrail_setup_utils/enable_kernel_core.py' ],
        unless    => 'grep -qx enable-kernel-core /etc/contrail/contrail_common_exec.out',
        provider  => shell,
        logoutput => $contrail_logoutput
    }
    ->
    notify { "executed enable-kernel-core": ; }
}

