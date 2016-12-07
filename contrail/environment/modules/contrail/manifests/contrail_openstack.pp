# == Class: contrail::contrail_openstack
#
# This class is used to configure software and services required
# to perfrom any additional functionality required on openstack node
# by contrail modules (e.g. create openstackrc, keystonerc, ec2rc files etc).
# Any new code needed to be executed on openstack node by contrail should be
# added here.
#
# === Parameters:
#
# [*openstack_ip*]
#     IP address of server running openstack services. If the server has
#     separate interfaces for management and control, this parameter
#     should provide control interface IP address.
#
# [*keystone_ip*]
#     IP address of server running keystone service. Should be specified if
#     keystone is running on a server other than openstack server.
#     (optional) - Defaults to "", meaning use openstack_ip.
#
# [*internal_vip*]
#     Virtual mgmt IP address for openstack modules
#     (optional) - Defaults to ""
#
# [*external_vip*]
#     Virtual IP address to be used for openstack HA functionality on
#     management interface.
#
# [*openstack_mgmt_ip*]
#     Management interface address of openstack node (if management and control are separate
#     interfaces on that node)
#     (optional) - Defaults to "", meaning use openstack_ip.
#
# [*keystone_admin_user*]
#     Keystone admin user.
#     (optional) - Defaults to "admin".
#
# [*keystone_admin_password*]
#     Keystone admin password.
#     (optional) - Defaults to "contrail123"
#
# [*keystone_admin_tenant*]
#     Keystone admin tenant name.
#     (optional) - Defaults to "admin".
#
# [*keystone_service_token*]
#     openstack service token value.
#     (optional) - Defaults to "contrail123"
#
# [*keystone_auth_protocol*]
#     Keystone authentication protocol.
#     (optional) - Defaults to "http".
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
# [*enable_ceilometer*]
#     Flag to include or exclude ceilometer service as part of openstack module dynamically.
#     (optional) - Defaults to false.
#
class contrail::contrail_openstack (
    $openstack_ip = $::contrail::params::openstack_ip_list[0],
    $keystone_ip = $::contrail::params::keystone_ip,
    $internal_vip = $::contrail::params::internal_vip,
    $external_vip = $::contrail::params::external_vip,
    $openstack_mgmt_ip = $::contrail::params::openstack_mgmt_ip_list_to_use[0],
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $keystone_service_token     = $::contrail::params::os_keystone_admin_token,
    $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $host_control_ip = $::contrail::params::host_ip,
    $enable_ceilometer = $::contrail::params::enable_ceilometer,
    $keystone_version  = $::contrail::params::keystone_version,
)  {
    # Main code for class

    #select the novncproxy based on presence of internal_vip

    if ($external_vip != '') {
        $vnc_base_url_port = '6080'
        $vnc_base_url_ip = $external_vip
    } elsif ($internal_vip != '' ) {
        $vnc_base_url_port = '6080'
        $vnc_base_url_ip = $internal_vip
    } else {
        $vnc_base_url_port = '5999'
        $vnc_base_url_ip = $openstack_mgmt_ip
    }

    include ::contrail::openstackrc
    # Create mysql token file.
    file { '/etc/contrail/mysql.token' :
        ensure  => present,
        mode    => '0400',
        group   => root,
        content => $::contrail::params::mysql_root_password
    } ->
    # Create keystonerc file.
    file { '/etc/contrail/keystonerc' :
        ensure  => present,
        content => template("${module_name}/keystonerc.erb"),
    } ->
    class {'::contrail::exec_create_ec2rc_file':}

    $nova_params =  {
      #'DEFAULT/novncproxy_base_url' => { value => "http://${vnc_base_url_ip}:${vnc_base_url_port}/vnc_auto.html"},
      'DEFAULT/ec2_private_dns_show_ip' => { value => 'False' },
    }
    create_resources(nova_config,$nova_params, {} )
}
