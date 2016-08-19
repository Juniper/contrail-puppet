class contrail::ctrl_details(
    $host_control_ip = $::contrail::params::host_ip,
    $openstack_mgmt_ip = $::contrail::params::openstack_mgmt_ip_list_to_use[0],
    $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
    $amqp_server_ip_to_use = $::contrail::params::amqp_server_ip_to_use,
    $quantum_port = $::contrail::params::quantum_port,
    $quantum_service_protocol = $::contrail::params::quantum_service_protocol,
    $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol,
    $internal_vip = $::contrail::params::internal_vip,
    $external_vip = $::contrail::params::external_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $vmware_ip = $::contrail::params::vmware_ip,
    $vmware_username = $::contrail::params::vmware_username,
    $vmware_password = $::contrail::params::vmware_password,
    $vmware_vswitch = $::contrail::params::vmware_vswitch,
    $haproxy = $::contrail::params::haproxy,
) {
    if $haproxy == true {
        $quantum_ip = '127.0.0.1'
    } else {
        $quantum_ip = $host_control_ip
    }

    file { '/etc/contrail/ctrl-details' :
        content => template("${module_name}/ctrl-details.erb"),
    }
}
