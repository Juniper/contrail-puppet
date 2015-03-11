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
class contrail::contrail_openstack (
    $openstack_ip = $::contrail::params::openstack_ip_list[0],
    $keystone_ip = $::contrail::params::keystone_ip,
    $internal_vip = $::contrail::params::internal_vip,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $keystone_service_token = $::contrail::params::keystone_service_token,
    $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) inherits ::contrail::params {
    # Main code for class
    # Create openstackrc file.
    file { "/etc/contrail/openstackrc" :
	ensure  => present,
	content => template("$module_name/openstackrc.erb"),
    }
    # Create openstackrc file.
    file { "/etc/contrail/keystonerc" :
	ensure  => present,
	content => template("$module_name/keystonerc.erb"),
    }
    # Create ec2rc file
    file { "/opt/contrail/bin/contrail-create-ec2rc.sh" :
        ensure  => present,
        mode => 0755,
        group => root,
        source => "puppet:///modules/$module_name/contrail-create-ec2rc.sh"
    }
    exec { "exec_create_ec2rc_file":
        command => "./contrail-create-ec2rc.sh",
        cwd => "/opt/contrail/bin/",
        provider => shell,
        require => [ File["/opt/contrail/bin/contrail-create-ec2rc.sh"] ],
        logoutput => $contrail_logoutput
    }
    # Set novncproxy_port to 5999, novncproxy_base_url to http://$openstack_mgmt_ip:5999/vnc_auto.html
    exec { "exec_set_novncproxy":
        command => "openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_port 5999 && openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_base_url http://$openstack_mgmt_ip:5999/vnc_auto.html && echo exec_set_novncproxy >> /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        require => [ File["/etc/nova/nova.conf"] ],
        logoutput => $contrail_logoutput
    }
    # Set service_neutron_metadata_proxy to True
    exec { "exec_set_service_neutron_metadata_proxy":
        command => "openstack-config --set /etc/nova/nova.conf DEFAULT service_neutron_metadata_proxy True && echo exec_set_service_neutron_metadata_proxy >> /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        require => [ File["/etc/nova/nova.conf"] ],
        logoutput => $contrail_logoutput
    }
}
