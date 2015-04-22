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
# [*database_ip_list*]
#     List of control interface IP addresses of all the nodes running
#     Database role (cassandra cluster). If current host is also running
#     database services, address of this server is specified as first entry in the list.
#
# [*database_ip_port*]
#     IP port number on which database (cassandra) service listening.
#     (optional) - Defaults to 9160
#
# [*analytics_data_ttl*]
#     Time for which analytics data is maintained.
#     (optional) - Defaults to 48 hours
#
# [*analytics_config_audit_ttl*]
#     TTL for config audit data in hours.
#     (optional) - Defaults to 168 hours.
#
# [*analytics_statistics_ttl*]
#     TTL for statistics data in hours.
#     (optional) - Defaults to 24 hours.
#
# [*analytics_flow_ttl*]
#     TTL for flow data in hours.
#     (optional) - Defaults to 2 hours.
#
# [*snmp_scan_frequency*]
#     SNMP full scan frequency (in seconds).
#     (optional) - Defaults to 600 seconds.
#
# [*snmp_fast_scan_frequency*]
#     SNMP fast scan frequency (in seconds).
#     (optional) - Defaults to 60 seconds.
#
# [*topology_scan_frequency*]
#     Topology scan frequency (in seconds).
#     (optional) - Defaults to 60 seconds.
#
# [*zookeeper_ip_list*]
#     List of control interface IP addresses of all servers running zookeeper services.
#     (optional) - Defaults to database_ip_list
#
# [*zk_ip_port*]
#     Zookeeper IP port number
#     (optional) - Defaults to "2181"
#
# [*analytics_syslog_port*]
#     TCP and UDP ports to listen on for receiving syslog messages. -1 to disable.
#     (optional) - Defaults to -1 (disable)
#
# [*internal_vip*]
#     Virtual IP on the control/data interface (internal network) to be used for openstack.
#     (optional) - Defaults to "".
#
# [*contrail_internal_vip*]
#     Virtual IP on the control/data interface (internal network) to be used for contrail.
#     (optional) - Defaults to "".
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::collector (
    $host_control_ip = $::contrail::params::host_ip,
    $config_ip = $::contrail::params::config_ip_list[0],
    $database_ip_list = $::contrail::params::database_ip_list,
    $database_ip_port = $::contrail::params::database_ip_port,
    $analytics_data_ttl = $::contrail::params::analytics_data_ttl,
    $analytics_config_audit_ttl = $::contrail::params::analytics_config_audit_ttl,
    $analytics_statistics_ttl = $::contrail::params::analytics_statistics_ttl,
    $analytics_flow_ttl = $::contrail::params::analytics_flow_ttl,
    $snmp_scan_frequency = $::contrail::params::snmp_scan_frequency,
    $snmp_fast_scan_frequency = $::contrail::params::snmp_fast_scan_frequency,
    $topology_scan_frequency = $::contrail::params::topology_scan_frequency,
    $zookeeper_ip_list = $::contrail::params::zk_ip_list_to_use,
    $zk_ip_port = $::contrail::params::zk_ip_port,
    $analytics_syslog_port = $::contrail::params::analytics_syslog_port,
    $internal_vip = $::contrail::params::internal_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) inherits ::contrail::params {

    # If internal VIP is configured, use that address as config_ip.
    if ($contrail_internal_vip != "") {
        $config_ip_to_use = $contrail_internal_vip
    }
    elsif ($internal_vip != "") {
        $config_ip_to_use = $internal_vip
    }
    else {
        $config_ip_to_use = $config_ip
    }

    # Main code for class
    case $::operatingsystem {
	Ubuntu: {
	      file {"/etc/init/supervisor-analytics.override": ensure => absent, require => Package['contrail-openstack-analytics']}
	      file { '/etc/init.d/supervisor-analytics':
		       ensure => link,
		 target => '/lib/init/upstart-job',
		 before => Service["supervisor-analytics"]
	      }


	}
    }

    contrail::lib::report_status { "collector_started":
        state => "collector_started",
        contrail_logoutput => $contrail_logoutput }
    ->
    # Ensure all needed packages are present
    package { 'contrail-openstack-analytics' : ensure => latest, notify => "Service[supervisor-analytics]"}
    ->
    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - supervisor, python-contrail, contrail-analytics, contrail-setup, contrail-nodemgr
    # For Centos/Fedora - contrail-api-pib, contrail-analytics, contrail-setup, contrail-nodemgr

    # Ensure all config files with correct content are present.
    file { "/etc/contrail/contrail-analytics-api.conf" :
	ensure  => present,
	require => Package["contrail-openstack-analytics"],
	content => template("$module_name/contrail-analytics-api.conf.erb"),
    }
    ->
    file { "/etc/contrail/contrail-collector.conf" :
	ensure  => present,
	require => Package["contrail-openstack-analytics"],
	content => template("$module_name/contrail-collector.conf.erb"),
    }
    ->
    file { "/etc/contrail/contrail-query-engine.conf" :
	ensure  => present,
	require => Package["contrail-openstack-analytics"],
	content => template("$module_name/contrail-query-engine.conf.erb"),
    }
    ->
    file { "/etc/contrail/contrail-snmp-collector.conf" :
        ensure  => present,
        require => Package["contrail-openstack-analytics"],
        content => template("$module_name/contrail-snmp-collector.conf.erb"),
    }
    ->
    file { "/etc/contrail/contrail-topology.conf" :
        ensure  => present,
        require => Package["contrail-openstack-analytics"],
        content => template("$module_name/contrail-topology.conf.erb"),
    }
    ->
    exec { "redis-conf-exec":
	command => "sed -i -e '/^[ ]*bind/s/^/#/' /etc/redis/redis.conf;chkconfig redis-server on; service redis-server restart && echo redis-conf-exec>> /etc/contrail/contrail-collector-exec.out",
	onlyif => "test -f /etc/redis/redis.conf",
	require => Package["contrail-openstack-analytics"],
	unless  => "grep -qx redis-conf-exec /etc/contrail/contrail-collector-exec.out",
	provider => shell,
	logoutput => $contrail_logoutput
    }
    ->
    # Ensure the services needed are running.
    service { "supervisor-analytics" :
	enable => true,
	require => [ Package['contrail-openstack-analytics']
		   ],
	subscribe => [ File['/etc/contrail/contrail-collector.conf'],
		       File['/etc/contrail/contrail-query-engine.conf'],
		       File['/etc/contrail/contrail-analytics-api.conf'] ],
	ensure => running,
    }
    ->
    contrail::lib::report_status { "collector_completed":
        state => "collector_completed",
        contrail_logoutput => $contrail_logoutput }

}
