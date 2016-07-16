class contrail::collector::config (
    $host_control_ip = $::contrail::params::host_ip,
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
    $redis_password = $::contrail::params::redis_password,
    $config_ip_to_use = $::contrail::params::config_ip_to_use,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $contrail_rabbit_servers= $::contrail::params::contrail_rabbit_servers,
    $redis_config_file = $::contrail::params::redis_config_file
) {

    $rest_api_port_to_use = $::contrail::params::rest_api_port_to_use
    $discovery_ip_to_use =  $::contrail::params::discovery_ip_to_use

     ## Cassandra Port for Cql has been changed to 9042.
    $database_ip_port_list = suffix($database_ip_list, ":9042")
    $cassandra_server_list = join($database_ip_port_list, ' ' )

    $kafka_broker_port_list = suffix($database_ip_list, ':9092')
    $kafka_broker_list =  join($kafka_broker_port_list, ' ')

    $zookeeper_ip_port_list = suffix($zookeeper_ip_list, ":$zk_ip_port")
    $zk_ip_list = join($zookeeper_ip_port_list, ',')

    $contrail_snmp_collector_ini_command ="/usr/bin/contrail-snmp-collector --conf_file /etc/contrail/contrail-snmp-collector.conf --conf_file /etc/contrail/contrail-keystone-auth.conf"
    $contrail_topology_ini_command ="/usr/bin/contrail-topology --conf_file /etc/contrail/contrail-topology.conf --conf_file /etc/contrail/contrail-keystone-auth.conf"
    $contrail_analytics_api_ini_command ="/usr/bin/contrail-analytics-api --conf_file /etc/contrail/contrail-analytics-api.conf --conf_file /etc/contrail/contrail-keystone-auth.conf"
    $contrail_alarm_gen_ini_command ="/usr/bin/contrail-alarm-gen --conf_file /etc/contrail/contrail-alarm-gen.conf --conf_file /etc/contrail/contrail-keystone-auth.conf"

    $redis_augeas_lens_to_use = 'spacevars.lns'

    if ($redis_password != "" ) {
        $redis_config = { 'redis_conf' => { 'requirepass' => $redis_password,},}
        Contrail_topology_ini_config['program:contrail-topology/user'] ->
        contrail_analytics_api_config { 'REDIS/redis_password' : value => $redis_password; } ->
        contrail_collector_config { 'REDIS/password': value => $redis_password; } ->
        contrail_query_engine_config { 'REDIS/password': value => $redis_password; } ->
        contrail::lib::augeas_conf_set { 'redis_conf_keys':
             config_file => $redis_config_file,
             settings_hash => $redis_config['redis_conf'],
             lens_to_use => $redis_augeas_lens_to_use,
        } ->
        Contrail::Lib::Augeas_conf_rm["remove_bind"]
    } else {
        Contrail_topology_ini_config['program:contrail-topology/user'] ->
        contrail_analytics_api_config { 'REDIS/redis_password' : ensure => absent; } ->
        contrail_collector_config { 'REDIS/password': ensure => absent; } ->
        contrail_query_engine_config { 'REDIS/password': ensure => absent; } ->
        Contrail::Lib::Augeas_conf_rm["remove_bind"]
    }

    contrail_analytics_api_config {
      'DEFAULTS/host_ip'          : value => $host_control_ip;
      'DEFAULTS/collectors'       : ensure => 'absent';
      'DEFAULTS/cassandra_server_list': value => "$cassandra_server_list";
      'DEFAULTS/rest_api_port'    : value => $rest_api_port_to_use;
      'DEFAULTS/http_server_port' : value => '8090';
      'DEFAULTS/rest_api_ip'      : value => '0.0.0.0';
      'DEFAULTS/log_local'        : value => '1';
      'DEFAULTS/log_level'        : value => 'SYS_NOTICE';
      'DEFAULTS/log_file'         : value => '/var/log/contrail/contrail-analytics-api.log';
      'DEFAULTS/analytics_data_ttl' : value => $analytics_data_ttl;
      'DEFAULTS/analytics_config_audit_ttl' : value => $analytics_config_audit_ttl;
      'DEFAULTS/analytics_statistics_ttl'   : value => $analytics_statistics_ttl;
      'DEFAULTS/analytics_flow_ttl' : value => $analytics_flow_ttl;
      'DEFAULTS/aaa_mode' : value => 'cloud-admin-only';
      'DISCOVERY/disc_server_ip'   : value => $config_ip_to_use;
      'DISCOVERY/disc_server_port' : value => '5998';
      'REDIS/redis_server_port'    : value => '6379';
      'REDIS/redis_query_port'     : value => '6379';
    } ->

    contrail_query_engine_config {
      'DEFAULT/hostip'          : value => $host_control_ip;
      'DEFAULT/cassandra_server_list'       : value => "$cassandra_server_list";
      'DEFAULT/collectors'       : ensure => 'absent';
      'DEFAULT/log_local'        : value => '1';
      'DEFAULT/log_level'        : value => 'SYS_NOTICE';
      'DEFAULT/log_file'         : value => '/var/log/contrail/contrail-query-engine.log';
      'REDIS/port'               : value => '6379';
      'REDIS/server'             : value => '127.0.0.1';
      'DISCOVERY/server'         : value => $config_ip_to_use;
      'DISCOVERY/port'           : value => '5998';
    } ->

    contrail_collector_config {
      'DEFAULT/hostip'          : value => $host_control_ip;
      'DEFAULT/cassandra_server_list'       : value => "$cassandra_server_list";
      'DEFAULT/zookeeper_server_list'       : value => "$zk_ip_list";
      'DEFAULT/kafka_broker_list': value => "$kafka_broker_list";
      'DEFAULT/syslog_port'      : value => $analytics_syslog_port;
      'DEFAULT/http_server_port' : value => '8089';
      'DEFAULT/log_local'        : value => '1';
      'DEFAULT/log_level'        : value => 'SYS_NOTICE';
      'DEFAULT/log_file'         : value => '/var/log/contrail/contrail-collector.log';
      'DEFAULT/analytics_data_ttl' : value => $analytics_data_ttl;
      'DEFAULT/analytics_config_audit_ttl' : value => $analytics_config_audit_ttl;
      'DEFAULT/analytics_statistics_ttl'   : value => $analytics_statistics_ttl;
      'DEFAULT/analytics_flow_ttl' : value => $analytics_flow_ttl;
      'COLLECTOR/port'           : value => '8086';
      'DISCOVERY/server'         : value => $config_ip_to_use;
      'REDIS/port'               : value => '6379';
      'REDIS/server'             : value => '127.0.0.1';
    } ->

    contrail_snmp_collector_config {
      'DEFAULTS/zookeeper'          : value => "$zk_ip_list";
      'DEFAULTS/log_local'          : value => '1';
      'DEFAULTS/log_level'          : value => 'SYS_NOTICE';
      'DEFAULTS/log_file'           : value => '/var/log/contrail/contrail-snmp-collector.log';
      'DEFAULTS/scan_frequency'     : value => $snmp_scan_frequency;
      'DEFAULTS/fast_scan_frequency': value => $snmp_fast_scan_frequency;
      'DEFAULTS/http_server_port'   : value => '5920';
      'DISCOVERY/disc_server_port' : value => '5998';
      'DISCOVERY/disc_server_ip'   : value => $discovery_ip_to_use;
    } ->

    contrail_analytics_nodemgr_config {
      'DEFAULT/server' : value => $config_ip_to_use;
      'DEFAULT/port'   : value => '5998';
    } ->

    contrail_alarm_gen_config {
      'DEFAULTS/host_ip'            : value => $host_control_ip;
      'DEFAULTS/zk_list'            : value => "$zk_ip_list";
      'DEFAULTS/kafka_broker_list'  : value => "$kafka_broker_list";
      'DEFAULTS/rabbitmq_server_list' : value => "$contrail_rabbit_servers";
      'DEFAULTS/http_server_port'   : value => '5995';
      'DEFAULTS/log_local'          : value => '1';
      'DEFAULTS/log_level'          : value => 'SYS_NOTICE';
      'DEFAULTS/log_file'           : value => '/var/log/contrail/contrail-alarm-gen.log';
      'DISCOVERY/disc_server_port' : value => '5998';
      'DISCOVERY/disc_server_ip'   : value => $config_ip_to_use;
    } ->

    contrail_topology_config {
      'DEFAULTS/zookeeper'          : value => "$zk_ip_list";
      'DEFAULTS/log_local'          : value => '1';
      'DEFAULTS/log_level'          : value => 'SYS_NOTICE';
      'DEFAULTS/log_file'           : value => '/var/log/contrail/contrail-topology.log';
      'DEFAULTS/scan_frequency'     : value => $topology_scan_frequency;
      'DISCOVERY/disc_server_ip'    : value => $config_ip_to_use;
      'DISCOVERY/disc_server_port'  : value => '5998';
    } ->

    contrail_alarm_gen_ini_config {
      'program:contrail-alarm-gen/command' : value => $contrail_alarm_gen_ini_command;
      'program:contrail-alarm-gen/priority' : value => '440';
      'program:contrail-alarm-gen/autostart' : value => 'true';
      'program:contrail-alarm-gen/killasgroup' : value => 'true';
      'program:contrail-alarm-gen/stopsignal' : value => 'KILL';
      'program:contrail-alarm-gen/stdout_capture_maxbytes' : value => '1MB';
      'program:contrail-alarm-gen/redirect_stderr' : value => 'true';
      'program:contrail-alarm-gen/stdout_logfile' : value => '/var/log/contrail/contrail-alarm-gen-stdout.log';
      'program:contrail-alarm-gen/stderr_logfile' : value => '/var/log/contrail/contrail-alarm-gen-stderr.log';
      'program:contrail-alarm-gen/startsecs' : value => '5';
      'program:contrail-alarm-gen/exitcodes' : value => '0';
      'program:contrail-alarm-gen/user' : value => 'contrail';
    } ->

    contrail_analytics_api_ini_config {
      'program:contrail-analytics-api/command' : value => $contrail_analytics_api_ini_command;
      'program:contrail-analytics-api/priority' : value => '440';
      'program:contrail-analytics-api/autostart' : value => 'true';
      'program:contrail-analytics-api/killasgroup' : value => 'true';
      'program:contrail-analytics-api/stopsignal' : value => 'KILL';
      'program:contrail-analytics-api/stdout_capture_maxbytes' : value => '1MB';
      'program:contrail-analytics-api/redirect_stderr' : value => 'true';
      'program:contrail-analytics-api/stdout_logfile' : value => '/var/log/contrail/contrail-analytics-api-stdout.log';
      'program:contrail-analytics-api/stderr_logfile' : value => '/var/log/contrail/contrail-analytics-api-stderr.log';
      'program:contrail-analytics-api/startsecs' : value => '5';
      'program:contrail-analytics-api/exitcodes' : value => '0';
      'program:contrail-analytics-api/user' : value => 'contrail';
    } ->

    contrail_snmp_collector_ini_config {
      'program:contrail-snmp-collector/command' : value => $contrail_snmp_collector_ini_command;
      'program:contrail-snmp-collector/priority' : value => '340';
      'program:contrail-snmp-collector/autostart' : value => 'true';
      'program:contrail-snmp-collector/killasgroup' : value => 'true';
      'program:contrail-snmp-collector/stopsignal' : value => 'KILL';
      'program:contrail-snmp-collector/stdout_capture_maxbytes' : value => '1MB';
      'program:contrail-snmp-collector/redirect_stderr' : value => 'true';
      'program:contrail-snmp-collector/stdout_logfile' : value => '/var/log/contrail/contrail-snmp-collector-stdout.log';
      'program:contrail-snmp-collector/stderr_logfile' : value => '/var/log/contrail/contrail-snmp-collector-stderr.log';
      'program:contrail-snmp-collector/startsecs' : value => '5';
      'program:contrail-snmp-collector/exitcodes' : value => '0';
      'program:contrail-snmp-collector/user' : value => 'contrail';
    } ->

    contrail_topology_ini_config {
      'program:contrail-topology/command' : value => $contrail_topology_ini_command;
      'program:contrail-topology/priority' : value => '340';
      'program:contrail-topology/autostart' : value => 'true';
      'program:contrail-topology/killasgroup' : value => 'true';
      'program:contrail-topology/stopsignal' : value => 'KILL';
      'program:contrail-topology/stdout_capture_maxbytes' : value => '1MB';
      'program:contrail-topology/redirect_stderr' : value => 'true';
      'program:contrail-topology/stdout_logfile' : value => '/var/log/contrail/contrail-snmp-collector-stdout.log';
      'program:contrail-topology/stderr_logfile' : value => '/var/log/contrail/contrail-snmp-collector-stderr.log';
      'program:contrail-topology/startsecs' : value => '5';
      'program:contrail-topology/exitcodes' : value => '0';
      'program:contrail-topology/user' : value => 'contrail';
    } ->

    contrail::lib::augeas_conf_rm { "remove_bind":
                key => 'bind',
                config_file => $redis_config_file,
                lens_to_use => $redis_augeas_lens_to_use,
    } ->
    contrail::lib::augeas_conf_rm { "remove_save":
                key => 'save',
                config_file => $redis_config_file,
                lens_to_use => $redis_augeas_lens_to_use,
    } ->
    contrail::lib::augeas_conf_rm { "remove_dbfilename":
                key => 'dbfilename',
                config_file => $redis_config_file,
                lens_to_use => $redis_augeas_lens_to_use,
    } ->

    file { '/etc/snmp':
       ensure  => directory,
    } ->
    file { '/etc/snmp/snmp.conf':
      content => 'mibs +ALL'
    }
}
