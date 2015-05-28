# == Class: contrail::provision_contrail
#
# This class is used to perform several provisioning tasks needed
# for contrail such as provision control node, provision external BGP
# connection, provision encapsulation type etc.
#
# === Parameters:
#
# [*keystone_admin_tenant*]
#     Keystone admin tenant name.
#
# [*keystone_admin_user*]
#     Keystone admin user name.
#
# [*keystone_admin_password*]
#     Keystone admin password.
#
# [*encap_priority*]
#     Encapsulation priority.
#
# [*config_ip*]
#     IP address of the server where config module of contrail cluster is
#     configured.
#
# [*openstack_ip*]
#     IP address of the server where openstack controller is configured.
#
# [*internal_vip*]
#     Virtual mgmt IP address for openstack modules
#     (optional) - Defaults to ""
#
# [*contrail_internal_vip*]
#     Virtual mgmt IP address for contrail modules
#     (optional) - Defaults to "", in which case value of internal_vip is used.
#
# [*router_asn*]
#     ASN for the router.
#
# [*control_ip_list*]
#     List of control interface IP addresses of all servers running contrail
#     controller node functionality.
#
# [*control_name_list*]
#     List of host names of all servers running contrail controller node
#     functionality.
#
# [*multi_tenancy*]
#     Flag to indicate if openstack multi-tenancy is enabled.
#     (optional) - Defaults to True.
#
# [*external_bgp*]
#     IP address of the external bgp peer.
#     (optional) - Defaults to "".
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::provision_contrail (
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $encap_priority = $::contrail::params::encap_priority,
    $config_ip = $::contrail::params::config_ip_list[0],
    $openstack_ip = $::contrail::params::openstack_ip_list[0],
    $internal_vip = $::contrail::params::internal_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $router_asn = $::contrail::params::router_asn,
    $control_ip_list = $::contrail::params::control_ip_list,
    $control_name_list = $::contrail::params::control_name_list,
    $multi_tenancy = $::contrail::params::multi_tenancy,
    $external_bgp = $::contrail::params::external_bgp,
    $config_ip_list = $::contrail::params::config_ip_list,
    $config_name_list = $::contrail::params::config_name_list,
    $database_ip_list = $::contrail::params::database_ip_list,
    $database_name_list = $::contrail::params::database_name_list,
    $collector_ip_list = $::contrail::params::collector_ip_list,
    $collector_name_list = $::contrail::params::collector_name_list,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {

    # Initialize the multi tenancy option will update latter based on vns argument
    if ($multi_tenancy == true) {
	$mt_options = "admin,$keystone_admin_password,$keystone_admin_tenant"
    } else {
	$mt_options = "None"
    }

    # calculate config ip to use.
    if ($contrail_internal_vip) {
        $config_ip_to_use = $contrail_internal_vip
    }
    elsif ($internal_vip) {
        $config_ip_to_use = $internal_vip
    }
    else {
        $config_ip_to_use = $config_ip
    }

    # calculate openstack ip to use.
    if ($internal_vip) {
        $openstack_ip_to_use = $internal_vip
    }
    else {
        $openstack_ip_to_use = $openstack_ip
    }

    $database_ip_list_for_shell = inline_template('<%= database_ip_list.map{ |ip| "#{ip}" }.join(",") %>')
    $database_name_list_for_shell = inline_template('<%= database_name_list.map{ |name| "#{name}" }.join(",") %>')

    $config_ip_list_for_shell = inline_template('<%= config_ip_list.map{ |ip| "#{ip}" }.join(",") %>')
    $config_name_list_for_shell = inline_template('<%= config_name_list.map{ |name| "#{name}" }.join(",") %>')


    $collector_ip_list_for_shell = inline_template('<%= collector_ip_list.map{ |ip| "#{ip}" }.join(",") %>')
    $collector_name_list_for_shell = inline_template('<%= collector_name_list.map{ |name| "#{name}" }.join(",") %>')


    $host_ip_list_for_shell = inline_template('<%= control_ip_list.map{ |ip| "#{ip}" }.join(",") %>')
    $host_name_list_for_shell = inline_template('<%= control_name_list.map{ |name| "#{name}" }.join(",") %>')
    $contrail_exec_provision_control = "python  exec_provision_control.py --api_server_ip \"$config_ip_to_use\" --api_server_port 8082 --host_name_list \"$host_name_list_for_shell\" --host_ip_list \"$host_ip_list_for_shell\" --router_asn \"$router_asn\" --mt_options \"$mt_options\" && echo exec-provision-control >> /etc/contrail/contrail_config_exec.out"

    file { "/etc/contrail/contrail_setup_utils/exec_provision_control.py" :
	ensure  => present,
	mode => 0755,
	group => root,
	source => "puppet:///modules/$module_name/exec_provision_control.py"
    }
    ->
    notify { "contrail contrail_exec_provision_control is $contrail_exec_provision_control":; }
    ->
    exec { "exec-provision-control" :
	command => $contrail_exec_provision_control,
	cwd => "/etc/contrail/contrail_setup_utils/",
	unless  => "grep -qx exec-provision-control /etc/contrail/contrail_config_exec.out",
	provider => shell,
    require => [ File["/etc/contrail/contrail_setup_utils/exec_provision_control.py"] ],
	logoutput => $contrail_logoutput
    }
    ->
    file { "/etc/contrail/contrail_setup_utils/setup_external_bgp.py" :
	    ensure  => present,
	    mode => 0755,
	    group => root,
	    source => "puppet:///modules/$module_name/setup_external_bgp.py"
    }
    ->
   exec { "provision-external-bgp" :
	command => "python /etc/contrail/contrail_setup_utils/setup_external_bgp.py --bgp_params \"$external_bgp\" --api_server_ip \"$config_ip_to_use\" --api_server_port 8082 --router_asn \"$router_asn\" --mt_options \"$mt_options\" && echo provision-external-bgp >> /etc/contrail/contrail_config_exec.out",
	require => [ File["/etc/contrail/contrail_setup_utils/setup_external_bgp.py"] ],
	unless  => "grep -qx provision-external-bgp /etc/contrail/contrail_config_exec.out",
	provider => shell,
	logoutput => $contrail_logoutput
    }
    ->
    exec { "provision-metadata-services" :
	command => "python /opt/contrail/utils/provision_linklocal.py --admin_user \"$keystone_admin_user\" --admin_password \"$keystone_admin_password\" --linklocal_service_name metadata --linklocal_service_ip 169.254.169.254 --linklocal_service_port 80 --ipfabric_service_ip \"$openstack_ip_to_use\"  --ipfabric_service_port 8775 --oper add && echo provision-metadata-services >> /etc/contrail/contrail_config_exec.out",
	unless  => "grep -qx provision-metadata-services /etc/contrail/contrail_config_exec.out",
	provider => shell,
	logoutput => $contrail_logoutput,
	tries => 100,
	try_sleep => 15,
    }
    ->
    exec { "provision-encap-type" :
	command => "python /opt/contrail/utils/provision_encap.py --admin_user \"$keystone_admin_user\" --admin_password \"$keystone_admin_password\" --encap_priority \"$encap_priority\" --oper add && echo provision-encap-type >> /etc/contrail/contrail_config_exec.out",
	unless  => "grep -qx provision-encap-type /etc/contrail/contrail_config_exec.out",
	provider => shell,
	logoutput => $contrail_logoutput,
	tries => 100,
	try_sleep => 15,
    }
    ->
    file { "/opt/contrail/provision_role.py" :
	    ensure  => present,
	    mode => 0755,
	    group => root,
	    source => "puppet:///modules/$module_name/provision_role.py"
    }
    ->
   exec { "provision-role-config" :
	command => "python /opt/contrail/provision_role.py $config_ip_list_for_shell $config_name_list_for_shell $config_ip $keystone_admin_user $keystone_admin_password $keystone_admin_tenant 'config' && echo provision-role-config >> /etc/contrail/contrail_config_exec.out",
	require => [ File["/opt/contrail/provision_role.py"] ],
	provider => shell,
	logoutput => $contrail_logoutput
    }
    ->
    exec { "provision-role-database" :
	command => "python /opt/contrail/provision_role.py $database_ip_list_for_shell $database_name_list_for_shell $config_ip $keystone_admin_user $keystone_admin_password $keystone_admin_tenant 'database' && echo provision-role-database- >> /etc/contrail/contrail_config_exec.out",
	require => [ File["/opt/contrail/provision_role.py"] ],
	provider => shell,
	logoutput => $contrail_logoutput
    }
    ->
    exec { "provision-role-collector" :
	command => "python /opt/contrail/provision_role.py $collector_ip_list_for_shell $collector_name_list_for_shell $config_ip $keystone_admin_user $keystone_admin_password $keystone_admin_tenant 'collector' && echo provision-role-collector >> /etc/contrail/contrail_config_exec.out",
	require => [ File["/opt/contrail/provision_role.py"] ],
	provider => shell,
	logoutput => $contrail_logoutput
    }

}
