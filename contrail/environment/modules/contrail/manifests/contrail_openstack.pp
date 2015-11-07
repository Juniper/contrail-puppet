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
    $keystone_service_token = $::contrail::params::keystone_service_token,
    $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $host_control_ip = $::contrail::params::host_ip,
    $enable_ceilometer = $::contrail::params::enable_ceilometer,
)  {
    include ::contrail::params
    # Main code for class

    #slect the novncproxy based on presence of internal_vip
    if ($internal_vip != ''){
        $novncproxy_port = '6999'
        $vnc_proxy_host = $host_control_ip
    } else {
        $novncproxy_port = '5999'
        $vnc_proxy_host = $openstack_mgmt_ip
    }

    if ($external_vip != '') {
        $vnc_base_url_ip = $external_vip
    } elsif ($internal_vip != '' ) {
        $vnc_base_url_ip = $internal_vip
    } else {
        $vnc_base_url_ip = $openstack_mgmt_ip
    }

    # Create mysql token file.
    file { '/etc/contrail/mysql.token' :
        ensure  => present,
        mode    => '0400',
        group   => root,
        content => $::contrail::params::mysql_root_password
    } ->
    # Create openstackrc file.
    file { '/etc/contrail/openstackrc' :
        ensure  => present,
        content => template("${module_name}/openstackrc.erb"),
    } ->
    # Create openstackrc file.
    file { '/etc/contrail/keystonerc' :
        ensure  => present,
        content => template("${module_name}/keystonerc.erb"),
    } ->
    # Create ec2rc file
    file { '/opt/contrail/bin/contrail-create-ec2rc.sh' :
        ensure => present,
        mode   => '0755',
        group  => root,
        source => "puppet:///modules/${module_name}/contrail-create-ec2rc.sh"
    } ->
    exec { 'exec_create_ec2rc_file':
        command   => './contrail-create-ec2rc.sh',
        cwd       => '/opt/contrail/bin/',
        provider  => shell,
        logoutput => $contrail_logoutput
    }
    $nova_params =  {
      #'DEFAULT/novncproxy_port' => { value => $novncproxy_port },
      'DEFAULT/novncproxy_base_url' => { value => "http://${vnc_base_url_ip}:${novncproxy_port}/vnc_auto.html"},
      #'DEFAULT/novncproxy_host' => { value => $vnc_proxy_host },
      #'DEFAULT/service_neutron_metadata_proxy' => { value => 'True' },
      'DEFAULT/ec2_private_dns_show_ip' => { value => 'False' },
    }
    create_resources(nova_config,$nova_params, {} )

    #glance_api_config { 'DEFAULT/registry_host': value => '0.0.0.0' }

    # Disable mpm_event apache module
    exec { "exec_disable_mpm_event":
        command => "a2dismod mpm_event && service apache2 restart && echo exec_disable_mpm_event>> /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => $contrail_logoutput
    }

    if ($enable_ceilometer) {
        # Set instance_usage_audit_period to hour
        $ceilometer_nova_params =  {
          'DEFAULT/instance_usage_audit_period' => { value => 'hour' },
          'DEFAULT/instance_usage_audit' => { value => 'True' },
        }
        create_resources(nova_config,$ceilometer_nova_params, {} )
    }
}
