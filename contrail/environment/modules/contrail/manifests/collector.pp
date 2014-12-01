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
class contrail::collector (
    $host_control_ip = $::contrail::params::host_ip,
    $config_ip = $::contrail::params::config_ip_list[0],
    $database_ip_list = $::contrail::params::database_ip_list,
    $database_ip_port = $::contrail::params::database_ip_port,
    $analytics_data_ttl = $::contrail::params::analytics_data_ttl,
    $analytics_syslog_port = $::contrail::params::analytics_syslog_port,
    $internal_vip = $::contrail::params::internal_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip
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

    # Ensure all needed packages are present
    package { 'contrail-openstack-analytics' : ensure => present,}
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
    exec { "redis-conf-exec":
	command => "sed -i -e '/^[ ]*bind/s/^/#/' /etc/redis/redis.conf;chkconfig redis-server on; service redis-server restart && echo redis-conf-exec>> /etc/contrail/contrail-collector-exec.out",
	onlyif => "test -f /etc/redis/redis.conf",
	require => Package["contrail-openstack-analytics"],
	unless  => "grep -qx redis-conf-exec /etc/contrail/contrail-collector-exec.out",
	provider => shell,
	logoutput => "true"
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
}
