# == Class: contrail::control
#
# This class is used to configure software and services required
# to run controller module of contrail software suit.
#
# === Parameters:
#
# [*host_control_ip*]
#     IP address of the server where contrail collector is being installed.
#     if server has separate interfaces for management and control, this
#     parameter should provide control interface IP address.
#
# [*config_ip*]
#     Control interface IP address of the server where config module of
#     contrail cluster is configured. If there are multiple config nodes
#     , IP address of first config node server is specified here.
#
# [*puppet_server*]
#     FQDN of puppet master, in case puppet master is used for certificates
#     (optional) - Defaults to "".
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::uninstall_control (
    $host_control_ip = $::contrail::params::host_ip,
    $config_ip = $::contrail::params::config_ip_to_use,
    $multi_tenancy_options = $::contrail::params::multi_tenancy_options,
    $router_asn =  $::contrail::params::router_asn,
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol,
    $keystone_ip = $::contrail::params::keystone_ip_to_use,
    $puppet_server = $::contrail::params::puppet_server,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    include ::contrail::params

    $config_ip_to_use = $::contrail::params::config_ip_to_use

    # Main class code begins here
    case $::operatingsystem {
        Ubuntu: {
                file { ['/etc/init/supervisor-control.override',
                        '/etc/init/supervisor-dns.override'] :
                    ensure  => absent,
                }
            #TODO, Is this really needed?
                # Below is temporary to work-around in Ubuntu as Service resource fails
                # as upstart is not correctly linked to /etc/init.d/service-name
        }
        default: {
        }
    }
    if ! defined(File['/etc/contrail/vnc_api_lib.ini']) {
        file { '/etc/contrail/vnc_api_lib.ini' :
            content => template("${module_name}/vnc_api_lib.ini.erb"),
        }
    }
    contrail::lib::report_status { 'uninstall_control_started':
        state              => 'uninstall_control_started',
        contrail_logoutput => $contrail_logoutput
    }
    ->
    exec { 'del-vnc-control' :
	command => "/bin/bash -c \"python /opt/contrail/utils/provision_control.py --api_server_ip $config_ip --api_server_port 8082 --host_name $::hostname  --host_ip $host_control_ip --router_asn $router_asn $multi_tenancy_options --oper del && echo del-vnc-control >> /etc/contrail/contrail_control_exec.out\"",
        unless    => 'grep -qx del-vnc-control /etc/contrail/contrail_control_exec.out',
	provider => shell,
        require => File['/etc/contrail/vnc_api_lib.ini'],
	logoutput => $contrail_logoutput
    } ->
/*
    service { 'supervisor-control' :
        ensure    => false,
    }
    ->

*/
/*
    service { 'contrail-named' :
        ensure    => false,
        enable    => stopped,
    }
    ->
*/
    package { 'contrail-openstack-control' : ensure => purged, notify => ['Exec[apt_auto_remove_control]']}
    ->
    exec{ "apt_auto_remove_control":
       command => "apt-get autoremove -y --purge",
       provider => shell,
       logoutput => $contrail_logoutput
    }

    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - supervisor, contrail-api-lib, contrail-control, contrail-dns,
    #                      contrail-setup, contrail-nodemgr
    # For Centos/Fedora - contrail-api-lib, contrail-control, contrail-setup, contrail-libs
    #                     contrail-dns, supervisor


    # Ensure all config files with correct content are present.
    file { [
           '/etc/contrail/contrail-dns.conf',
           '/etc/contrail/contrail-control.conf',
           '/etc/contrail/contrail-control-nodemgr.conf',
           ] :
	ensure => absent,
    }
/*
   # update rndc conf
    exec { 'update-rndc-conf-file' :
        command   => "sudo sed -i 's/secret \"secret123\"/secret \"xvysmOR8lnUQRBcunkC6vg==\"/g' /etc/contrail/dns/rndc.conf && echo update-rndc-conf-file >> /etc/contrail/contrail_control_exec.out",
        require   => Package['contrail-openstack-control'],
        onlyif    => 'test -f /etc/contrail/dns/rndc.conf',
        unless    => 'grep -qx update-rndc-conf-file /etc/contrail/contrail_control_exec.out',
        provider  => shell,
        logoutput => $contrail_logoutput
    }
*/
    # Ensure the services needed are running.
    contrail::lib::report_status { 'uninstall_control_completed':
        state              => 'uninstall_control_completed',
        contrail_logoutput => $contrail_logoutput
    }
}
