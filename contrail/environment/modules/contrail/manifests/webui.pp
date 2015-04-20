# == Class: contrail::webui
#
# This class is used to configure software and services required
# to run webui module of contrail software suit.
#
# === Parameters:
#
# [*config_ip*]
#     Control Interface IP address of the server where config module of 
#     contrail cluster is configured. If there are multiple config nodes
#     this parameter uses IP address of first config node (index = 0).
#
# [*collector_ip*]
#     IP address of the server where analytics module of
#     contrail cluster is configured. If this host is also running
#     collector role, local host address is preferred here, else
#     one of collector nodes is chosen.
#
# [*openstack_ip*]
#     Control interface IP address of openstack node.
#
# [*database_ip_list*]
#     List of control interface IP addresses of all servers running cassandra
#     database roles.
#
# [*is_storage_master*]
#     Flag to Indicate if this server is also running contrail storage master role.A
#     (optional) - Default is false.
#
# [*keystone_ip*]
#     IP address of keystone node, if keystone is run outside openstack.
#     (optional) - Defaults to "", meaning use openstack_ip.
#
# [*internal_vip*]
#     Virtual IP for openstack nodes in case of HA configuration.
#     (Optional) - Defaults to "", meaning no HA configuration.
#
# [*contrail_internal_vip*]
#     Virtual IP for contrail config nodes in case of HA configuration.
#     (Optional) - Defaults to "", meaning no HA configuration.
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::webui (
    $config_ip = $::contrail::params::config_ip_list[0],
    $collector_ip = $::contrail::params::collector_ip_list[0],
    $openstack_ip = $::contrail::params::openstack_ip_list[0],
    $database_ip_list =  $::contrail::params::database_ip_list,
    $is_storage_master = $::contrail::params::storage_enabled,
    $keystone_ip = $::contrail::params::keystone_ip,
    $internal_vip = $::contrail::params::internal_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) inherits ::contrail::params {
    case $::operatingsystem {
        Ubuntu: {
            file {"/etc/init/supervisor-webui.override": ensure => absent, require => Package['contrail-openstack-webui']}
            # Below is temporary to work-around in Ubuntu as Service resource fails
            # as upstart is not correctly linked to /etc/init.d/service-name
            file { '/etc/init.d/supervisor-webui':
                ensure => link,
                target => '/lib/init/upstart-job',
                before => Service["supervisor-webui"]
            }
        }
        default: {
        }
    }

    # Set all variables as needed for config file using the class parameters.
    # if contrail_internal_vip is "", but internal_vip is not "", set contrail_internal_vip
    # to internal_vip.
    if ($contrail_internal_vip == "") {
        $contrail_internal_vip_to_use = $internal_vip
    }
    else {
        $contrail_internal_vip_to_use = $contrail_internal_vip
    }
    # Set config_ip to be used to internal_vip, if internal_vip is not "".
    if ($contrail_internal_vip_to_use != "") {
        $config_ip_to_use = $contrail_internal_vip_to_use
        $collector_ip_to_use = $contrail_internal_vip_to_use
    }
    else {
        $config_ip_to_use = $config_ip
        $collector_ip_to_use = $collector_ip
    }
    # Set openstack_ip to be used to internal_vip, if internal_vip is not "".
    if ($internal_vip != "") {
        $openstack_ip_to_use = $internal_vip
    }
    else {
        $openstack_ip_to_use = $openstack_ip
    }
    # Set keystone_ip to be used.
    if ($keystone_ip != "") {
        $keystone_ip_to_use = $keystone_ip
    }
    elsif ($internal_vip != "") {
        $keystone_ip_to_use = $internal_vip
    }
    else {
        $keystone_ip_to_use = $openstack_ip
    }

    # Print all the variables
    notify { "webui - config_ip = $config_ip":;}
    notify { "webui - config_ip_to_use = $config_ip_to_use":;}
    notify { "webui - collector_ip = $ccollector_ip":;}
    notify { "webui - collector_ip_to_use = $ccollector_ip_to_use":;}
    notify { "webui - openstack_ip = $openstack_ip":;}
    notify { "webui - openstack_ip_to_use = $openstack_ip_to_use":;}
    notify { "webui - database_ip_list = $database_ip_list":;}
    notify { "webui - is_storage_master = $is_storage_master":;}
    notify { "webui - keystone_ip = $keystone_ip":;}
    notify { "webui - keystone_ip_to_use = $keystone_ip_to_use":;}
    notify { "webui - internal_vip = $internal_vip":;}
    notify { "webui - contrail_internal_vip = $contrail_internal_vip":;}
    notify { "webui - contrail_internal_vip_to_use = $contrail_internal_vip_to_use":;}

    contrail::lib::report_status { "webui_started":
        state => "webui_started", 
        contrail_logoutput => $contrail_logoutput }
    ->
    # Ensure all needed packages are present
    package { 'contrail-openstack-webui' : ensure => latest, notify => "Service[supervisor-webui]"}

    if ($is_storage_master) {
        package { 'contrail-web-storage' :
            ensure => latest,}
	-> file { "storage.config.global.js":
            path => "/usr/src/contrail/contrail-web-storage/webroot/common/config/storage.config.global.js",
            ensure => present,
            require => Package["contrail-web-storage"],
            content => template("$module_name/storage.config.global.js.erb"),
        }
        -> Service['supervisor-webui']
    } else {
        package { 'contrail-web-storage' :
            ensure => absent,}
	-> file { "storage.config.global.js":
            path => "/usr/src/contrail/contrail-web-storage/webroot/common/config/storage.config.global.js",
            ensure => absent,
            content => template("$module_name/storage.config.global.js.erb"),
        }
        -> Service['supervisor-webui']
    }
    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - contrail-nodemgr, contrail-webui, contrail-setup, supervisor
    # For Centos/Fedora - contrail-api-lib, contrail-webui, contrail-setup, supervisor
    # Ensure global config js file is present.
    file { "/etc/contrail/config.global.js" :
        ensure  => present,
        require => Package["contrail-openstack-webui"],
        content => template("$module_name/config.global.js.erb"),
    }
    ->
    # Ensure the services needed are running. The individual services are left
    # under control of supervisor. Hence puppet only checks for continued operation
    # of supervisor-webui service, which in turn monitors status of individual
    # services needed for webui role.
    service { "supervisor-webui" :
        enable => true,
        subscribe => File['/etc/contrail/config.global.js'],
        ensure => running,
    }
    ->
    contrail::lib::report_status { "webui_completed":
        state => "webui_completed", 
        contrail_logoutput => $contrail_logoutput }

}
