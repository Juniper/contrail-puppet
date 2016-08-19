class contrail::compute::exec_set_rabbitmq_tcp_params (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    # check_wsrep
    file { '/opt/contrail/bin/set_rabbit_tcp_params.py' :
           ensure => present,
           mode   => '0755',
           group  => root,
           source => "puppet:///modules/${module_name}/set_rabbit_tcp_params.py"
    } ->
    exec { 'exec_set_rabbitmq_tcp_params' :
            command   => 'python /opt/contrail/bin/set_rabbit_tcp_params.py && echo exec_set_rabbitmq_tcp_params >> /etc/contrail/contrail_openstack_exec.out',
            cwd       => '/opt/contrail/bin/',
            unless    => 'grep -qx exec_set_rabbitmq_tcp_params /etc/contrail/contrail_openstack_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
    }
    ->
    notify { "executed exec_set_rabbitmq_tcp_params" :; }
}
