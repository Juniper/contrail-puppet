class contrail::provision_metadata_services (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $openstack_ip_to_use = $::contrail::provision_contrail::openstack_ip_to_use
) {
    exec { 'provision-metadata-services' :
            command   => "python /opt/contrail/utils/provision_linklocal.py --admin_user \"${keystone_admin_user}\" --admin_password \"${keystone_admin_password}\" --linklocal_service_name metadata --linklocal_service_ip 169.254.169.254 --linklocal_service_port 80 --ipfabric_service_ip \"${openstack_ip_to_use}\"  --ipfabric_service_port 8775 --oper add && echo provision-metadata-services >> /etc/contrail/contrail_config_exec.out",
            unless    => 'grep -qx provision-metadata-services /etc/contrail/contrail_config_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput,
    }
}

