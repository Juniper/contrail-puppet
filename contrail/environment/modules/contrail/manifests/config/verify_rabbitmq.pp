class contrail::config::verify_rabbitmq (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $master,
    $host_control_ip,
    $config_ip_list
) {
    file { '/etc/contrail/form_rmq_cluster.sh' :
              mode   => '0755',
              group  => root,
              source => "puppet:///modules/${module_name}/form_rmq_cluster.sh"
    } ->
    exec { 'verify-rabbitmq' :
            command   => "/etc/contrail/form_rmq_cluster.sh ${master} ${host_control_ip} ${config_ip_list} & echo verify-rabbitmq >> /etc/contrail/contrail_config_exec.out",
            unless    => 'grep -qx verify-rabbitmq /etc/contrail/contrail_config_exec.out',
            provider  => shell,
            logoutput => true,
    }
    ->
    notify { "executed verify-rabbitmq":; }
}
