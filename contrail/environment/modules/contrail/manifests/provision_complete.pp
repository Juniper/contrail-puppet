class contrail::provision_complete(
    $state = undef,
    $host_control_ip = $::contrail::params::host_ip,
    $openstack_ip_list = $::contrail::params::openstack_ip_list,
    $internal_vip =  $::contrail::params::internal_vip,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
)
{
    contrail::lib::report_status { $state:
        state => $state, 
        contrail_logoutput => $contrail_logoutput }
    ->
    exec { "do-reboot-server" :
	command => "/sbin/reboot && echo do-reboot-server >> /etc/contrail/contrail_common_exec.out",
	onlyif  => "grep -qx flag-reboot-server /etc/contrail/contrail_compute_exec.out",
        unless => "grep -qx do-reboot-server /etc/contrail/contrail_common_exec.out",
	provider => shell,
	logoutput => $contrail_logoutput
    }

}
