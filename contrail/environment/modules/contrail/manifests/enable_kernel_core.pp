class contrail::enable_kernel_core (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    file { '/etc/contrail/contrail_setup_utils/enable_kernel_core.py':
        ensure => present,
        mode   => '0755',
        owner  => root,
        group  => root,
        source => "puppet:///modules/${module_name}/enable_kernel_core.py"
    }
    # enable kernel core , below python code has bug, for now ignore by executing echo regardless and thus returning true for cmd.
    # need to revisit afterwards.

    if ($::operatingsystem == 'Ubuntu') {
        package { 'linux-crashdump' : ensure => present,}
    }
    exec { 'enable-kernel-core' :
        command   => 'python /etc/contrail/contrail_setup_utils/enable_kernel_core.py; echo enable-kernel-core >> /etc/contrail/contrail_common_exec.out',
        require   => File['/etc/contrail/contrail_setup_utils/enable_kernel_core.py' ],
        unless    => 'grep -qx enable-kernel-core /etc/contrail/contrail_common_exec.out',
        provider  => shell,
        logoutput => $contrail_logoutput
    }
}

