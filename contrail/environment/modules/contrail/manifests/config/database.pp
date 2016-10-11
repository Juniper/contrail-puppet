class contrail::config::database (
  $host_control_ip = $::contrail::params::host_ip,
  $config_ip = $::contrail::params::config_ip_to_use,
  $config_ip_list = $::contrail::params::config_ip_list,
  $internal_vip = $::contrail::params::internal_vip,
  $zookeeper_ip_list = $::contrail::params::config_ip_list,
  $database_initial_token = $::contrail::params::database_initial_token,
  $database_dir = $::contrail::params::database_dir,
  $analytics_data_dir = $::contrail::params::analytics_data_dir,
  $ssd_data_dir = $::contrail::params::ssd_data_dir,
  $contrail_logoutput = $::contrail::params::contrail_logoutput,
  $database_minimum_diskGB = $::contrail::params::database_minimum_diskGB,
  $host_roles = $::contrail::params::host_roles,
  $config_manage_db = $::contrail::params::config_manage_db,
) {
    if (!('database' in $host_roles) and $config_manage_db == true) {
           $database_ip_list_to_use = $config_ip_list
           # Main Class code
           case $::operatingsystem {
            Ubuntu: {
                $contrail_cassandra_dir = '/etc/cassandra'
            }
            'Centos', 'Fedora': {
                $contrail_cassandra_dir = '/etc/cassandra/conf'
            }
            default: {
                $contrail_cassandra_dir = '/etc/cassandra/conf'
            }
            }

            if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
            $zk_myid_file = '/var/lib/zookeeper/myid'
            } else {
            $zk_myid_file = '/etc/zookeeper/conf/myid'
            }

            # set database_index
            $tmp_index = inline_template('<%= @database_ip_list_to_use.index(@host_control_ip) %>')
            if ($tmp_index == undef) {
            fail("Host ${host_control_ip} not found in servers of config roles")
            }
            $database_index = $tmp_index + 1

            # set cassandra_seeds list
            if (size($database_ip_list_to_use) > 1) {
            $cassandra_seeds = difference($database_ip_list_to_use, [$database_ip_list_to_use[0]])
            }
            else {
            $cassandra_seeds = $database_ip_list_to_use
            }

            $zk_ip_list_for_shell = join($zookeeper_ip_list, ' ')
            $zookeeper_ip_port_list = suffix($zookeeper_ip_list, ":$zk_ip_port")
            $zk_ip_port_list_str = join($zookeeper_ip_port_list, ',')
            $zk_ip_list_len = size($zookeeper_ip_list)
            if ($zk_ip_list_len > 1) {
              $replication_factor = 2
            } else {
              $replication_factor = 1
            }
            $contrail_zk_exec_cmd = "/bin/bash /etc/contrail/contrail_setup_utils/config-zk-files-setup.sh ${::operatingsystem} ${database_index} ${zk_ip_list_for_shell} && echo setup-config-zk-files-setup >> /etc/contrail/contrail-config-exec.out"

            # Debug - Print all variables
            notify { "Database - contrail cassandra dir is ${contrail_cassandra_dir}":; } ->
            notify { "Database - host_control_ip = ${host_control_ip}":;} ->
            notify { "Database - config_ip = ${config_ip}":;} ->
            notify { "Database - internal_vip = ${internal_vip}":;} ->
            notify { "Database - database_ip_list_to_use = ${database_ip_list_to_use}":;} ->
            notify { "Database - zookeeper_ip_list = ${zookeeper_ip_list}":;} ->
            notify { "Database - database_index = ${database_index}":;} ->
            notify { "Database - cassandra_seeds = ${cassandra_seeds}":;} ->
            exec {'Create database dir':
                command   => "mkdir -p ${database_dir}",
                unless    => "test -d ${database_dir}",
                provider  => shell,
                logoutput => $contrail_logoutput
            } ->
            file { $database_dir :
              ensure  => directory,
              owner   => cassandra,
              group   => cassandra,
            } ->
            class {'::contrail::config_cassandra':
                cassandra_seeds => $cassandra_seeds,
                contrail_cassandra_dir => $contrail_cassandra_dir,
                    cassandra_cluster_name => "\'ConfigContrail\'"
            } ->
            file { '/etc/zookeeper/conf/zoo.cfg':
            ensure  => present,
            content => template("${module_name}/zoo.cfg.erb"),
            } ->
            class {'::contrail::config_zk_files_setup':
            database_index => $database_index,
            zk_myid_file   => $zk_myid_file
            } ->
            contrail_database_nodemgr_config {
              'DEFAULT/hostip': value => $host_control_ip;
              'DEFAULT/minimum_diskGB' : value => $database_minimum_diskGB;
              'DISCOVERY/server' : value => $config_ip;
              'DISCOVERY/port' : value => '5998';
            } ->
            file { '/etc/contrail/database_nodemgr_param' :
            ensure  => present,
            content => template("${module_name}/database_nodemgr_param.erb"),
            }

	    if ($analytics_data_dir != '') {
		Notify["Database - cassandra_seeds = ${cassandra_seeds}"] ->
		# Make dir ContrailAnalytics in cassandra database folder
		exec {'Create analytics database dir':
		    command   => "mkdir -p ${analytics_data_dir}",
		    unless    => "test -d ${analytics_data_dir}",
		    provider  => shell,
		    logoutput => $contrail_logoutput
		} ->
		file { $analytics_data_dir :
                    ensure  => directory,
                    owner   => cassandra,
                    group   => cassandra,
                } ->
                file { "${database_dir}/ContrailAnalytics":
		    ensure  => link,
		    target  => "${analytics_data_dir}/ContrailAnalyticsCql",
		    require => File[$database_dir],
		    owner   => cassandra,
		    group   => cassandra,
		}
	    }
	    if ($ssd_data_dir != '') {
	        Notify["Database - cassandra_seeds = ${cassandra_seeds}"] ->
		exec {'Create analytics ssd database dir':
		    command   => "mkdir -p ${ssd_data_dir}",
		    unless    => "test -d ${ssd_data_dir}",
		    provider  => shell,
		    logoutput => $contrail_logoutput
		}->
		file { $ssd_data_dir :
		    ensure  => directory,
		    owner   => cassandra,
		    group   => cassandra,
		}
	    }
            # Below is temporary to work-around in Ubuntu as Service resource fails
            # as upstart is not correctly linked to /etc/init.d/service-name
            if ($::operatingsystem == 'Ubuntu') {
            File['/etc/zookeeper/conf/zoo.cfg'] ->
            file { '/etc/init.d/supervisord-contrail-database':
                ensure  => link,
                target  => '/lib/init/upstart-job',
            } ->
            File ['/etc/zookeeper/conf/log4j.properties'] -> File ['/etc/zookeeper/conf/environment'] ->
            File [$zk_myid_file] ~> Service['zookeeper']
            }
            contain ::contrail::config_cassandra
            contain ::contrail::config_zk_files_setup

            $database_sysctl_settings = {
              'fs.file-max' => { value => 165535 },
            }
            create_resources(sysctl::value, $database_sysctl_settings, {} )
    }
}
