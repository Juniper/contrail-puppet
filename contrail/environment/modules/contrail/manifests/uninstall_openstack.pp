# == Class: contrail::openstack

# This class is used to configure software and services required
# to run openstack module of contrail software suit.
#
# === Parameters:
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::uninstall_openstack (
    $mysql_root_password = $::contrail::params::mysql_root_password,
    $host_control_ip = $::contrail::params::host_ip,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    include ::contrail::params

    # Set all variables as needed for config file using the class parameters.
    # if contrail_internal_vip is "", but internal_vip is not "", set contrail_internal_vip
    # to internal_vip.
    contrail::lib::report_status { 'uninstall_openstack_started':
        state              => 'uninstall_openstack_started',
        contrail_logoutput => $contrail_logoutput }
    ->
    class {'::contrail::delete_conductor':
        conductor_idx => $conductor_idx
    }
    ->
    class {'::contrail::delete_consoleauth':
        consoleauth_idx -> $consoleauth_idx
    }
    ->
    class {'::contrail::delete_scheduler':
         scheduler_idx => $scheduler_idx
    }
    ->
    class {'::contrail::delete_console':
        console_idx => $console_idx
    }
    ->
    class {'::contrail::remove_mysql_cmon_user':
         mysql_root_password => $mysql_root_password,
         host_control_ip => $host_control_ip
    }
    ->
    class {'::contrail::remove_mysql_root_user':
        mysql_root_password => $mysql_root_password,
        host_control_ip => $host_control_ip
    }
    ->
    class {'::contrail::remove_mysql_flush_privileges'
        mysql_root_password => $mysql_root_password
    }

    service { ['contrail-hamon','cmon', 'apache2', 'mysql'] :
        ensure    => false ,
        enable    => false,
    }
    ->
    # Ensure all needed packages are present
    package { ['contrail-openstack' ,'apache2' ,'memcached','glance-api','glance-registry','cinder-api','cinder-common','cinder-scheduler','python-nova','nova-common','python-numpy','heat-common','heat-api','heat-api-cfn','openstack-dashboard','nova-api','nova-novncproxy','nova-scheduler','nova-objectstore','nova-consoleauth','nova-conductor','contrail-openstack-dashboard', 'mysql', 'keystone', 'mysql-server-wsrep','mysql-common'] :
        ensure => purged,
        notify => ["Exec[apt_auto_remove_openstack]"],
    }
    ->
    #if puppet provides glob use that
    include ::contrail::remove_mysql_log_files
    ->
    include ::contrail::apt_auto_remove_purge

    ->

    contrail::lib::report_status { 'uninstall_openstack_completed':
        state              => 'uninstall_openstack_completed',
        contrail_logoutput => $contrail_logoutput
    }

}
