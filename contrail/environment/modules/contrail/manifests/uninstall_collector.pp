# == Class: contrail::collector
#
# This class is used to configure software and services required
# to run collector or analytics module of contrail software suit.
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
#     contrail cluster is configured. If there are multiple config nodes,
#     address of the first config node is specified here.
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::uninstall_collector (
    $host_control_ip = $::contrail::params::host_ip,
    $config_ip = $::contrail::params::config_ip_to_use,
    $multi_tenancy_options = $::contrail::params::multi_tenancy_options,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
)  {
    include ::contrail::params
    case $::operatingsystem {
        Ubuntu: {
        }
        default: { ## TODO 
        }
    }

    contrail::lib::report_status { 'uninstall_collector_started':
        state              => 'uninstall_collector_started',
        contrail_logoutput => $contrail_logoutput }
    ->
    class {'::contrail::delete_role_collector':
            config_ip => $config_ip,
            hostname => $hostname,
            host_control_ip => $host_control_ip,
            multi_tenancy_options => $multi_tenancy_options
    }
    ->
    # Ensure all needed packages are present
    package { 'contrail-openstack-analytics' :
        ensure => purged,
        notify => ["Exec[apt_auto_remove_collector]"],
    }
    ->
    exec { "apt_auto_remove_collector":
        command => "apt-get autoremove -y --purge",
        provider => shell,
        logoutput => $contrail_logoutput
    }
    ->

    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - supervisor, python-contrail, contrail-analytics, contrail-setup, contrail-nodemgr
    # For Centos/Fedora - contrail-api-pib, contrail-analytics, contrail-setup, contrail-nodemgr

    file { [
	    '/etc/contrail/contrail-analytics-api.conf',
            '/etc/contrail/contrail-collector.conf',
            '/etc/contrail/contrail-query-engine.conf',
            '/etc/contrail/contrail-snmp-collector.conf',
            '/etc/contrail/supervisord_analytics_files/contrail-snmp-collector.ini',
            '/etc/contrail/contrail-analytics-nodemgr.conf',
            '/etc/contrail/contrail-alarm-gen.conf',
            '/etc/contrail/contrail-topology.conf',
            '/etc/redis/redis.conf',
           ]:
        ensure  => absent,
    } ->

    # Ensure all config files with correct content are present.
    # Ensure the services needed are running.
    service { 'supervisor-analytics' :
        ensure    => false ,
    }
    ->
    contrail::lib::report_status { 'uninstall_collector_completed':
        state              => 'uninstall_collector_completed',
        contrail_logoutput => $contrail_logoutput }

    contain ::contrail::delete_role_collector
}

