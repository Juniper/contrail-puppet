##: TODO: Docuement class
class contrail::provision_complete(
    $state = undef,
    $host_control_ip = $::contrail::params::host_ip,
    $openstack_ip_list = $::contrail::params::openstack_ip_list,
    $internal_vip =  $::contrail::params::internal_vip,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $enable_module = $::contrail::params::enable_post_provision
)
{
    if ($enable_module) {
        contrail::lib::post_openstack { 'post_openstack':
            host_control_ip    => $host_control_ip,
            openstack_ip_list  => $openstack_ip_list,
            internal_vip       => $internal_vip,
            contrail_logoutput => $contrail_logoutput
        } ->
        contrail::lib::report_status { $state: } ->
        class {'::contrail::do_reboot_server':
            reboot_flag => "provision_complete_reboot",
        }
        contain ::contrail::do_reboot_server
    }
}
