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
class contrail::database (
    $host_control_ip = $::contrail::params::host_ip,
    $config_ip = $::contrail::params::config_ip_to_use,
    $database_ip_list = $::contrail::params::database_ip_list,
    $internal_vip = $::contrail::params::internal_vip,
    $zookeeper_ip_list = $::contrail::params::database_ip_list,
    $database_initial_token = $::contrail::params::database_initial_token,
    $database_dir = $::contrail::params::database_dir,
    $analytics_data_dir = $::contrail::params::analytics_data_dir,
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

    # set database_index
    $tmp_index = inline_template('<%= @database_ip_list.index(@host_control_ip) %>')
    if ($tmp_index == nil) {
        fail("Host $host_control_ip not found in servers of database roles")
    }
    $database_index = $tmp_index + 1

    # set cassandra_seeds list
    if (size($data_base_ip_list) > 1) {
        $cassandra_seeds = difference($database_ip_list, [$host_control_ip])
    }
    else {
        $cassandra_seeds = $database_ip_list
    }
    if ($multi_tenancy == true) {
	$multi_options = "--admin_user admin --admin_password $keystone_admin_password --admin_tenant_name $keystone_admin_tenant"
    } else {
	$multi_options = ""
    }

    $provision_opp = "del"
    $zk_ip_list_for_shell = inline_template('<%= @zookeeper_ip_list.map{ |ip| "#{ip}" }.join(" ") %>')
    $contrail_zk_exec_cmd = "/bin/bash /etc/contrail/contrail_setup_utils/config-zk-files-setup.sh $operatingsystem $database_index $zk_ip_list_for_shell && echo setup-config-zk-files-setup >> /etc/contrail/contrail-config-exec.out"

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

    exec { "un-provision-role-database" :
	command => "python /usr/share/contrail-utils/provision_database_node.py --api_server_ip $config_ip_to_use --host_name $hostname --host_ip $host_control_ip  --oper $provision_opp $multi_options && echo un-provision-role-config-$provision_opp >> /etc/contrail/contrail_config_exec.out",
#	require => [ ],
	provider => shell,
	logoutput => $contrail_logoutput
    }
    ->
    # Ensure the services needed are running.
    service { "supervisor-database" :
        enable => false,
        ensure => stopped,
    }

    ->
    # Ensure all needed packages are absent
    package { 'contrail-openstack-database' : ensure => latest, notify => "Service[supervisor-database]"}
    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - cassandra (>= 1.1.12) , contrail-setup, supervisor
    # For Centos/Fedora - contrail-api-lib, contrail-database, contrail-setup, openstack-quantum-contrail, supervisor
/*
    ->
    exec { "exec-config-host-entry" :
        command   => 'echo \"$config_ip   $system_name\" >> /etc/hosts && echo exec-config-host-entry >> /etc/contrail/contrail_database_exec.out',
        unless    => ["grep -q $config_ip /etc/hosts",
                      "grep -qx exec-config-host-entry /etc/contrail/contrail_database_exec.out"],
        provider => "shell",
        require => Package['contrail-openstack-database'],
        logoutput => $contrail_logoutput
    }
    ->
    # database venv installation
    exec { "database-venv" :
        command   => '/bin/bash -c "source ../bin/activate && pip install * && echo database-venv >> /etc/contrail/contrail_database_exec.out"',
        cwd       => '/opt/contrail/database-venv/archive',
        unless    => [ "[ ! -d /opt/contrail/database-venv/archive ]",
                       "[ ! -f /opt/contrail/database-venv/bin/activate ]",
                       "grep -qx database-venv /etc/contrail/contrail_database_exec.out"],
        require   => Package['contrail-openstack-database'],
        provider => "shell",
        logoutput => $contrail_logoutput
    }
*/
    ->
    file { "$database_dir" :
        ensure  => directory,
        require => Package['contrail-openstack-database']
    }
    ->
    file { "$contrail_cassandra_dir/cassandra.yaml" :
        ensure  => absent,
    }
    ->
    file { "$contrail_cassandra_dir/cassandra-env.sh" :
        ensure  => absent,
    }
    # Below is temporary to work-around in Ubuntu as Service resource fails
    ->  
/*
 # as upstart is not correctly linked to /etc/init.d/service-name
    if ($operatingsystem == "Ubuntu") {
	file { '/etc/init.d/supervisord-contrail-database':
	    ensure => link,
	    target => '/lib/init/upstart-job',
            require => File["$contrail_cassandra_dir/cassandra-env.sh"],
	    before => Service["supervisor-database"]
	}
    }
*/
    # set high session timeout to survive glance led disk activity
    file { "/etc/contrail/contrail_setup_utils/config-zk-files-setup.sh":
        ensure  => absent,
    }
/*
    ->
    notify { "contrail contrail_zk_exec_cmd is $contrail_zk_exec_cmd":; }
    ->
    exec { "setup-config-zk-files-setup" :
        command => $contrail_zk_exec_cmd,
        require => File["/etc/contrail/contrail_setup_utils/config-zk-files-setup.sh"],
        unless  => "grep -qx setup-config-zk-files-setup /etc/contrail/contrail-config-exec.out",
        provider => shell,
        logoutput => $contrail_logoutput
    }
*/
    ->
    file { "/etc/contrail/contrail-database-nodemgr.conf" :
        ensure  => absent,
    }
    ->
    file { "/etc/contrail/database_nodemgr_param" :
	ensure  => absent,
    }
    ->
    file { "/opt/contrail/bin/database-server-setup.sh":
	ensure  => absent,
    }
/*
    exec { "setup-database-server-setup" :
	command => "/opt/contrail/bin/database-server-setup.sh; echo setup-database-server-setup >> /etc/contrail/contrail-compute-exec.out",
	require => File["/opt/contrail/bin/database-server-setup.sh"],
	unless  => "grep -qx setup-database-server-setup /etc/contrail/contrail-compute-exec.out",
	provider => shell,
	logoutput => $contrail_logoutput
    }
*/
    ->
    contrail::lib::report_status { "uninstall_database_completed":
        state => "database_completed", 
        contrail_logoutput => $contrail_logoutput }

}
