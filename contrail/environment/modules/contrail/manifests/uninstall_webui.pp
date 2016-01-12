# == Class: contrail::webui

# This class is used to configure software and services required
# to run webui module of contrail software suit.
#
# === Parameters:
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::uninstall_webui (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    include ::contrail::params
    case $::operatingsystem {
        Ubuntu: {
            file {'/etc/init/supervisor-webui.override':
                ensure  => absent,
                require => Package['contrail-openstack-webui']
            }
            # Below is temporary to work-around in Ubuntu as Service resource fails
            # as upstart is not correctly linked to /etc/init.d/service-name
            file { '/etc/init.d/supervisor-webui':
                ensure => link,
                target => '/lib/init/upstart-job',
                before => Service['supervisor-webui']
            }
        }
        default: {
        }
    }

    # Set all variables as needed for config file using the class parameters.
    # if contrail_internal_vip is "", but internal_vip is not "", set contrail_internal_vip
    # to internal_vip.
    $config_ip_to_use = $::contrail::params::config_ip_to_use
    $collector_ip_to_use = $::contrail::params::collector_ip_to_use
    $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use
    $openstack_ip_to_use = $::contrail::params::openstack_ip_to_use


    contrail::lib::report_status { 'uninstall_webui_started':
        state              => 'uninstall_webui_started',
        contrail_logoutput => $contrail_logoutput }
    ->
    # Ensure all needed packages are present
    package { 'contrail-openstack-webui' :
        ensure => purged,
        notify => ["Exec[apt_auto_remove_webui]"],
    }
    ->
    include ::contrail::apt_auto_remove_purge

    if ($is_storage_master) {
        package { 'contrail-web-storage' :
            ensure => latest,
        }
        ->
        file { 'storage.config.global.js':
            ensure  => present,
            path    => '/usr/src/contrail/contrail-web-storage/webroot/common/config/storage.config.global.js',
            content => template("${module_name}/storage.config.global.js.erb"),
        }
        -> Service['supervisor-webui']
    } else {
        package { 'contrail-web-storage' :
            ensure => absent,
        }
        ->
        file { 'storage.config.global.js':
            ensure  => absent,
            path    => '/usr/src/contrail/contrail-web-storage/webroot/common/config/storage.config.global.js',
            content => template("${module_name}/storage.config.global.js.erb"),
        }
        -> Service['supervisor-webui']
    }
    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - contrail-nodemgr, contrail-webui, contrail-setup, supervisor
    # For Centos/Fedora - contrail-api-lib, contrail-webui, contrail-setup, supervisor
    # Ensure global config js file is present.
    file { '/etc/contrail/config.global.js' :
        ensure  => absent,
    }
    ->
    # Ensure the services needed are running. The individual services are left
    # under control of supervisor. Hence puppet only checks for continued operation
    # of supervisor-webui service, which in turn monitors status of individual
    # services needed for webui role.
    service { 'supervisor-webui' :
        ensure    => false,
        enable    => false,
    }
    ->
    contrail::lib::report_status { 'uninstall_webui_completed':
        state              => 'uninstall_webui_completed',
        contrail_logoutput => $contrail_logoutput
    }

}
