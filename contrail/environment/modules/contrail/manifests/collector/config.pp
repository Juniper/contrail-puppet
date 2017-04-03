class contrail::collector::config (
    $host_control_ip = $::contrail::params::host_ip,
    $database_ip_list = $::contrail::params::database_ip_list,
    $database_ip_port = $::contrail::params::database_ip_port,
    $collector_ip_list = $::contrail::params::collector_ip_list,
    $collector_ip_port_list = $::contrail::params::collector_ip_port_list,
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
    $config_ip_list = $::contrail::params::config_ip_list,
    $config_ip_to_use = $::contrail::params::config_ip_to_use,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $contrail_rabbit_servers= $::contrail::params::contrail_rabbit_servers,
    $rabbit_use_ssl     = $::contrail::params::rabbit_ssl_support,
    $kombu_ssl_ca_certs = $::contrail::params::kombu_ssl_ca_certs,
    $kombu_ssl_certfile = $::contrail::params::kombu_ssl_certfile,
    $kombu_ssl_keyfile  = $::contrail::params::kombu_ssl_keyfile,
    $redis_config_file = $::contrail::params::redis_config_file,
    $host_roles = $::contrail::params::host_roles,
) {

    $rest_api_port_to_use = $::contrail::params::rest_api_port_to_use
     ## Cassandra Port for Cql has been changed to 9042.
    $database_ip_port_list = suffix($database_ip_list, ":9042")
    $cassandra_server_list = join($database_ip_port_list, ' ' )

    $redis_ip_port_list = suffix($collector_ip_list, ":6379")
    $redis_server_list = join($redis_ip_port_list, ' ')

    $kafka_broker_port_list = suffix($database_ip_list, ':9092')
    $kafka_broker_list =  join($kafka_broker_port_list, ' ')

    $zookeeper_ip_port_list = suffix($zookeeper_ip_list, ":$zk_ip_port")
    $zk_ip_list = join($zookeeper_ip_port_list, ',')

    $api_server_ip_port_list = suffix($config_ip_list, ":8082")
    $api_server_list = join($api_server_ip_port_list, ' ')

    $analytics_api_server_to_use = "${config_ip_to_use}:8082"

    $redis_augeas_lens_to_use = 'spacevars.lns'

    if ($redis_password != "" ) {
        $redis_config = { 'redis_conf' => { 'requirepass' => $redis_password,},}
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
        contrail_analytics_api_config { 'REDIS/redis_password' : ensure => absent; } ->
        contrail_collector_config { 'REDIS/password': ensure => absent; } ->
        contrail_query_engine_config { 'REDIS/password': ensure => absent; } ->
        Contrail::Lib::Augeas_conf_rm["remove_bind"]
    }

    contrail_analytics_api_config {
      'DEFAULTS/host_ip'          : value => $host_control_ip;
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
      'DEFAULTS/aaa_mode' : value => 'rbac';
      'DEFAULTS/api_server' : value => $analytics_api_server_to_use;
      'DEFAULTS/zk_list'           : value => $zk_ip_list;
      'DEFAULTS/collectors'        : value => $collector_ip_port_list;
      'REDIS/redis_query_port'     : value => '6379';
      'REDIS/redis_uve_list'       : value => $redis_server_list;
    } ->

    contrail_query_engine_config {
      'DEFAULT/hostip'          : value => $host_control_ip;
      'DEFAULT/cassandra_server_list'       : value => "$cassandra_server_list";
      'DEFAULT/log_local'        : value => '1';
      'DEFAULT/log_level'        : value => 'SYS_NOTICE';
      'DEFAULT/log_file'         : value => '/var/log/contrail/contrail-query-engine.log';
      'DEFAULT/collectors'       : value => $collector_ip_port_list;
      'REDIS/port'               : value => '6379';
      'REDIS/server'             : value => '127.0.0.1';
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
      'API_SERVER/api_server_list'  : value => $api_server_list;
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
      'DEFAULTS/collectors'         : value => $collector_ip_port_list;
      'API_SERVER/api_server_list'  : value => $api_server_list;
    } ->

    contrail_analytics_nodemgr_config {
      'COLLECTOR/server_list': value => $collector_ip_port_list;
    } ->

    contrail_alarm_gen_config {
      'DEFAULTS/host_ip'            : value => $host_control_ip;
      'DEFAULTS/zk_list'            : value => "$zk_ip_list";
      'DEFAULTS/kafka_broker_list'  : value => "$kafka_broker_list";
      'DEFAULTS/rabbitmq_server_list' : value => "$contrail_rabbit_servers";
      'DEFAULTS/rabbitmq_use_ssl'     : value => $rabbit_use_ssl;
      'DEFAULTS/kombu_ssl_ca_certs' : value => $kombu_ssl_ca_certs;
      'DEFAULTS/kombu_ssl_certfile' : value => $kombu_ssl_certfile;
      'DEFAULTS/kombu_ssl_keyfile'  : value => $kombu_ssl_keyfile;
      'DEFAULTS/http_server_port'   : value => '5995';
      'DEFAULTS/log_local'          : value => '1';
      'DEFAULTS/log_level'          : value => 'SYS_NOTICE';
      'DEFAULTS/log_file'           : value => '/var/log/contrail/contrail-alarm-gen.log';
      'DEFAULTS/collectors'         : value => $collector_ip_port_list;
      'REDIS/redis_uve_list'        : value => $redis_server_list;
      'API_SERVER/api_server_list'  : value => $api_server_list;
    } ->

    contrail_topology_config {
      'DEFAULTS/zookeeper'          : value => "$zk_ip_list";
      'DEFAULTS/log_local'          : value => '1';
      'DEFAULTS/log_level'          : value => 'SYS_NOTICE';
      'DEFAULTS/log_file'           : value => '/var/log/contrail/contrail-topology.log';
      'DEFAULTS/scan_frequency'     : value => $topology_scan_frequency;
      'DEFAULTS/collectors'         : value => $collector_ip_port_list;
      'API_SERVER/api_server_list'  : value => $api_server_list;
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
    if (!('config' in $host_roles)) {
        contain ::contrail::keystone
    }
}
