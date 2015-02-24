class contrail::provision_complete(
    $state = undef
)
{
    $host_control_ip = $::contrail::params::host_ip
    $openstack_ip_list = $::contrail::params::openstack_ip_list
    $internal_vip =  $::contrail::params::internal_vip



    contrail::lib::post_openstack{post_openstack: host_control_ip => $host_control_ip, openstack_ip_list => $openstack_ip_list, internal_vip => $internal_vip}
    ->
    contrail::lib::report_status { $state: state => $state}
    ->
    exec { "do-reboot-server" :
	command => "reboot && do-reboot-server >> /etc/contrail/contrail_common_exec.out",
	onlyif  => "grep -qx flag-reboot-server /etc/contrail/contrail_compute_exec.out",
	provider => shell,
	logoutput => 'true'
    }

}


