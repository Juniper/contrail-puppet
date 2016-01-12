class contrail::compute::update_dev_net_config (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $update_dev_net_cmd = false,
) {
    if ( $update_dev_net_cmd ) {
        file { '/etc/contrail/contrail_setup_utils/update_dev_net_config_files.py':
                ensure => present,
                mode   => '0755',
                owner  => root,
                group  => root,
                source => "puppet:///modules/${module_name}/update_dev_net_config_files.py"
        } ->
        exec { 'update-dev-net-config' :
                command   => $update_dev_net_cmd,
                unless    => 'grep -qx update-dev-net-config /etc/contrail/contrail_compute_exec.out',
                provider  => shell,
                logoutput => $contrail_logoutput
        }
        ->
        notify { "Executed Update dev net config : ${update_dev_net_cmd}":; }
    }
}
