# == Class: contrail::databasE
#
# This class is used to configure software and services required
# to run cassdandra database module used by contrail software suit.
#
# === Parameters:
#
# [*host_control_ip*]
#     IP address of the server where database module is being installed.
#     if server has separate interfaces for management and control, this
#     parameter should provide control interface IP address.
#
# [*config_ip*]
#     IP address of the server where config module of contrail cluster is
#     configured. In multiple config nodes setup, specify address of first
#     config node. If HA is configured (internal VIP not null), the actual
#     address that gets used is internal VIP.
#
# [*database_ip_list*]
#     List of control interface IPs of all the servers running database role.
#     This is used to derive following variables used by this module.
#     - cassandra_seeds : In case of single DB node, set to database_ip_list
#       else, set to database_ip_list, minus current node.
#     - zookeeper_ip_list : set to database_ip_list (Also provided as separate
#       parameter in case user would like to separate zookeeper from DB.
#     - database_index - Index of this DB node in list of database_ip_list (1-based).
#
# [*internal_vip*]
#     Virtual IP for openstack nodes in case of HA configuration.
#     (Optional) - Defaults to "", meaning no HA configuration.
#
# [*zookeeper_ip_list*]
#     list of control interface IPs of all nodes running zookeeper service.
#     (optional) - Specify only if zookeeper server list is different from DB server
#                  list. Currently supported for same list. Default database_ip_list.
#
# [*database_initial_token*]
#     Token to be used for database seeds.
#     (optional) - Defaults to 0.
#
# [*database_dir*]
#     Directory to be used for database data files.
#     (optional) - Defaults to "/var/lib/cassandra".
#
# [*analytics_data_dir*]
#     Directory to be used for analytics data files. Used when
#     analytics data to be kept in a separate partition with
#     link created from database data dir to the analytics partition dir
#     (optional) - Defaults to "".
#
# [*ssd_data_dir*]
#     Directory to be used for ssd data files (commit logs).
#     (optional) - Defaults to "".
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
# [*database_minimum_diskGB*]
#     Minimum disk space needed in GB for database.
#     (optional) - Defaults to 256
#
class contrail::uninstall_database (
    $host_control_ip = $::contrail::params::host_ip,
    $config_ip = $::contrail::params::config_ip_to_use,
    $database_ip_list = $::contrail::params::database_ip_list,
    $internal_vip = $::contrail::params::internal_vip,
    $zookeeper_ip_list = $::contrail::params::database_ip_list,
    $database_initial_token = $::contrail::params::database_initial_token,
    $database_dir = $::contrail::params::database_dir,
    $analytics_data_dir = $::contrail::params::analytics_data_dir,
    $multi_tenancy_options =  $::contrail::params::multi_tenancy_options,
    $ssd_data_dir = $::contrail::params::ssd_data_dir,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $database_minimum_diskGB = $::contrail::params::database_minimum_diskGB,
) inherits ::contrail::params {
    # Main Class code
    case $::operatingsystem {
        Ubuntu: {
            $contrail_cassandra_dir = "/etc/cassandra"
            file {"/etc/init/supervisord-contrail-database.override":
            ensure => absent,
            require => Package['contrail-openstack-database']}
        }
        Centos: {
            $contrail_cassandra_dir = "/etc/cassandra/conf"
        }
        Fedora: {
            $contrail_cassandra_dir = "/etc/cassandra/conf"
        }
        default: {
             $contrail_cassandra_dir = "/etc/cassandra/conf"
        }
    }


    # Debug - Print all variables
    notify { "Database - contrail cassandra dir is $contrail_cassandra_dir":; }
    notify { "Database - host_control_ip = $host_control_ip":;}
    notify { "Database - config_ip = $config_ip":;}
    notify { "Database - internal_vip = $internal_vip":;}
    notify { "Database - database_ip_list = $database_ip_list":;}
    notify { "Database - zookeeper_ip_list = $zookeeper_ip_list":;}
    notify { "Database - database_index = $database_index":;}
    notify { "Database - cassandra_seeds = $cassandra_seeds":;}
    if ($analytics_data_dir != "") {
        # Make dir ContrailAnalytics in cassandra database folder
        file { "$database_dir/ContrailAnalytics":
            ensure => link,
            target => "$analytics_data_dir/ContrailAnalytics",
            require => File["$database_dir"],
            notify => Service["supervisor-database"]
        }
    }
    contrail::lib::report_status { "uninstall_database_started":
        state => "uninstall_database_started", 
        contrail_logoutput => $contrail_logoutput }
    ->
    class { '::contrail::delete_role_database':
            config_ip_to_use => $config_ip_to_use,
            hostname => $hostname,
            host_control_ip => $host_control_ip,
            multi_tenancy_options => $multi_tenancy_options
    }
    ->
    # Ensure the services needed are running.
    service { "supervisor-database" :
        enable => false,
        ensure => stopped,
    }

    ->
    # Ensure all needed packages are absent
    package { 'contrail-openstack-database' : ensure => purged, notify =>  ["Exec[apt_auto_remove_database]"]}
    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - cassandra (>= 1.1.12) , contrail-setup, supervisor
    # For Centos/Fedora - contrail-api-lib, contrail-database, contrail-setup, openstack-quantum-contrail, supervisor
    ->
    include ::contrail::apt_auto_remove_purge
    ->
    file { [
            "${contrail_cassandra_dir}/cassandra.yaml",
            "$contrail_cassandra_dir/cassandra-env.sh",
            "/etc/contrail/contrail_setup_utils/config-zk-files-setup.sh",
            "/etc/contrail/contrail-database-nodemgr.conf",
            "/etc/contrail/database_nodemgr_param",
            "/opt/contrail/bin/database-server-setup.sh",
           ]:
         ensure => absent,
    }

    ->
    contrail::lib::report_status { "uninstall_database_completed":
        state => "database_completed", 
        contrail_logoutput => $contrail_logoutput }

}
