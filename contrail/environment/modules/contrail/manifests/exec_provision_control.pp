class contrail::exec_provision_control (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $contrail_exec_provision_control = false
) {
    if ( $contrail_exec_provision_control ) {
        file { '/etc/contrail/contrail_setup_utils/exec_provision_control.py' :
            ensure => present,
            mode   => '0755',
            group  => root,
            source => "puppet:///modules/${module_name}/exec_provision_control.py"
        }
        ->
        notify { "contrail contrail_exec_provision_control is ${contrail_exec_provision_control}":; }
        ->
        exec { 'exec-provision-control' :
            command   => $contrail_exec_provision_control,
            cwd       => '/etc/contrail/contrail_setup_utils/',
            unless    => 'grep -qx exec-provision-control /etc/contrail/contrail_config_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
        }
        ->
        notify { "executed exec_provision_control":; }
    }
}

