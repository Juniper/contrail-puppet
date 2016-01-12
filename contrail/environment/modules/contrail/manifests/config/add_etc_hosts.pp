class contrail::config::add_etc_hosts (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $cfgm_ip_list_shell,
    $cfgm_name_list_shell
) {
    file { '/etc/contrail/add_etc_host.py' :
                mode   => '0755',
                group  => root,
                source => "puppet:///modules/${module_name}/add_etc_host.py"
    } ->
    exec { 'add-etc-hosts' :
            command   => "python /etc/contrail/add_etc_host.py ${cfgm_ip_list_shell} ${cfgm_name_list_shell} && echo add-etc-hosts >> /etc/contrail/contrail_config_exec.out",
            unless    => 'grep -qx add-etc-hosts /etc/contrail/contrail_config_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
    }
}
