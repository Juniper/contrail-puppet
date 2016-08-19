class contrail::delete_vnc_control (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $config_ip,
    $host_control_ip,
    $router_asn,
    $multi_tenancy_options
) {
    exec { 'del-vnc-control' :
	command => "/bin/bash -c \"python /opt/contrail/utils/provision_control.py --api_server_ip $config_ip --api_server_port 8082 --host_name $::hostname  --host_ip $host_control_ip --router_asn $router_asn $multi_tenancy_options --oper del && echo del-vnc-control >> /etc/contrail/contrail_control_exec.out\"",
        unless    => 'grep -qx del-vnc-control /etc/contrail/contrail_control_exec.out',
	provider => shell,
        require => File['/etc/contrail/vnc_api_lib.ini'],
	logoutput => $contrail_logoutput
    }
    ->
    notify { "executed delete_vnc_control" :; }
}

