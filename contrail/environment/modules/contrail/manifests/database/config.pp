
class contrail::database::config (
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
) {

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

    # set database_index
    $tmp_index = inline_template('<%= @database_ip_list.index(@host_control_ip) %>')
    if ($tmp_index == nil) {
        fail("Host ${host_control_ip} not found in servers of database roles")
    }
    $database_index = $tmp_index + 1

    # set cassandra_seeds list
    if (size($::contrail::params::data_base_ip_list) > 1) {
        $cassandra_seeds = difference($database_ip_list, [$host_control_ip])
    }
    else {
        $cassandra_seeds = $database_ip_list
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
    notify { "Database - contrail cassandra dir is ${contrail_cassandra_dir}":; }
    notify { "Database - host_control_ip = ${host_control_ip}":;}
    notify { "Database - config_ip = ${config_ip}":;}
    notify { "Database - internal_vip = ${internal_vip}":;}
    notify { "Database - database_ip_list = ${database_ip_list}":;}
    notify { "Database - zookeeper_ip_list = ${zookeeper_ip_list}":;}
    notify { "Database - database_index = ${database_index}":;}
    notify { "Database - cassandra_seeds = ${cassandra_seeds}":;}
    if ($analytics_data_dir != '') {
        # Make dir ContrailAnalytics in cassandra database folder
        file { "${database_dir}/ContrailAnalytics":
            ensure  => link,
            target  => "${analytics_data_dir}/ContrailAnalyticsCql",
            require => File[$database_dir],
            owner   => cassandra,
            group   => cassandra,
        }
    }
    file { $database_dir :
        ensure  => directory,
        owner   => cassandra,
        group   => cassandra,
    }
    ->

    file { "${contrail_cassandra_dir}/cassandra.yaml" :
        ensure  => present,
        content => template("${module_name}/cassandra.yaml.erb"),
    }
    ->
    file { "${contrail_cassandra_dir}/cassandra-env.sh" :
        ensure  => present,
        content => template("${module_name}/cassandra-env.sh.erb"),
    }

    # Ensure kafka/config/server.properties file is present with right content.
    $kafka_server_properties_file = '/usr/share/kafka/config/server.properties'
    $kafka_server_properties_config = { 'kafka_server_properties' => {
            'broker.id' => $tmp_index,
            'advertised.host.name' => $host_control_ip,
            'zookeeper.connect' => $zk_ip_port_list_str,
            'default.replication.factor' => $replication_factor,
            'port' => '9092',
            'log.cleaner.enable' => 'true',
            'log.cleanup.policy' => 'compact',
            'delete.topic.enable' => 'true',
        },
    }

    $kafka_server_properties_keys = keys($kafka_server_properties_config['kafka_server_properties'])
    $kafka_server_augeas_lens_to_use = 'properties.lns'
    contrail::lib::augeas_conf_set { $kafka_server_properties_keys:
            config_file => $kafka_server_properties_file,
            settings_hash => $kafka_server_properties_config['kafka_server_properties'],
            lens_to_use => $kafka_server_augeas_lens_to_use,
    }
    contrail::lib::augeas_conf_rm {"remove_key_listeners":
            key => 'listeners',
            config_file => $kafka_server_properties_file,
            lens_to_use => $kafka_server_augeas_lens_to_use,
    }

    # Ensure kafka/config/log4j.properties file is present with right content.
    $kafka_log4j_properties_file = '/usr/share/kafka/config/log4j.properties'
    $kafka_log4j_properties_config = { 'kafka_log4j_properties' => {
            'log4j.rootLogger' => 'INFO, stdout',
            'log4j.appender.kafkaAppender' => 'org.apache.log4j.RollingFileAppender',
            'log4j.appender.kafkaAppender.MaxBackupIndex' => '10',
            'log4j.appender.stateChangeAppender' => 'org.apache.log4j.RollingFileAppender',
            'log4j.appender.stateChangeAppender.MaxBackupIndex' => '10',
            'log4j.appender.requestAppender' => 'org.apache.log4j.RollingFileAppender',
            'log4j.appender.requestAppender.MaxBackupIndex' => '10',
            'log4j.appender.cleanerAppender' => 'org.apache.log4j.RollingFileAppender',
            'log4j.appender.cleanerAppender.MaxBackupIndex' => '10',
            'log4j.appender.controllerAppender' => 'org.apache.log4j.RollingFileAppender',
            'log4j.appender.controllerAppender.MaxBackupIndex' => '10',
        },
    }
    $kafka_log4j_properties_keys = keys($kafka_log4j_properties_config['kafka_log4j_properties'])
    $kafka_log4j_augeas_lens_to_use = 'properties.lns'
    contrail::lib::augeas_conf_ins { ['kafka.logs.dir']:
            config_file => $kafka_log4j_properties_file,
            settings_hash => {'kafka.logs.dir' => 'logs',},
            lens_to_use => $kafka_log4j_augeas_lens_to_use,

    }
    contrail::lib::augeas_conf_set { $kafka_log4j_properties_keys:
            config_file => $kafka_log4j_properties_file,
            settings_hash => $kafka_log4j_properties_config['kafka_log4j_properties'],
            lens_to_use => $kafka_log4j_augeas_lens_to_use,
    }

    ->
    file { '/etc/zookeeper/conf/zoo.cfg':
        ensure  => present,
        content => template("${module_name}/zoo.cfg.erb"),
    }

    #File['/usr/share/kafka/config/log4j.properties'] -> File['/etc/contrail/contrail_setup_utils/config-zk-files-setup.sh']
    # Below is temporary to work-around in Ubuntu as Service resource fails
    # as upstart is not correctly linked to /etc/init.d/service-name
    if ($::operatingsystem == 'Ubuntu') {
        file { '/etc/init.d/supervisord-contrail-database':
            ensure  => link,
            target  => '/lib/init/upstart-job',
            require => File["${contrail_cassandra_dir}/cassandra-env.sh"],
        }
        # Replaced the below script with augeas
        # File['/etc/init.d/supervisord-contrail-database'] -> File['/etc/contrail/contrail_setup_utils/config-zk-files-setup.sh']
        File['/etc/init.d/supervisord-contrail-database'] -> File['/etc/zookeeper/conf/zoo.cfg'] ->
        File ['/etc/zookeeper/conf/log4j.properties'] -> File ['/etc/zookeeper/conf/environment'] ->
        File ['/var/lib/zookeeper/myid']
    }
    # set high session timeout to survive glance led disk activity
    # Commented out call to old exec
    #class {'::contrail::database::config_zk_files_setup':
    #    contrail_zk_exec_cmd => $contrail_zk_exec_cmd
    #}
    # Replaced exec with call to augeas in this class
    class {'::contrail::database::new_config_zk_files_setup':
        database_index => $database_index
    }

    contrail_database_nodemgr_config {
      'DEFAULT/hostip': value => $host_control_ip;
      'DEFAULT/minimum_diskGB' : value => $database_minimum_diskGB;
      'DISCOVERY/server' : value => $config_ip;
      'DISCOVERY/port' : value => '5998';
    }

    file { '/etc/contrail/database_nodemgr_param' :
        ensure  => present,
        content => template("${module_name}/database_nodemgr_param.erb"),
    }
}
