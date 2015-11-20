class contrail::collector::config (
    $host_control_ip = $::contrail::params::host_ip,
    $config_ip = $::contrail::params::config_ip_list[0],
    $keystone_ip = $::contrail::params::keystone_ip,
    $openstack_ip = $::contrail::params::openstack_ip_list[0],
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
    $internal_vip = $::contrail::params::internal_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol,
    $keystone_auth_port = $::contrail::params::keystone_auth_port,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $keystone_insecure_flag = $::contrail::params::keystone_insecure_flag,
    $redis_password = $::contrail::params::redis_password,
    $config_ip_to_use = $::contrail::params::config_ip_to_use,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $contrail_topology_conf = $contrail::params::contrail_topology_conf,
    $contrail_alarm_gen_conf = $contrail::params::contrail_alarm_gen_conf,
    $contrail_snmp_collector_conf = $contrail::params::contrail_snmp_collector_conf,
    $contrail_analytics_nodemgr_conf = $contrail::params::contrail_analytics_nodemgr_conf,
    $contrail_analytics_api_conf = $contrail::params::contrail_analytics_api_conf,
    $contrail_keystone_auth_conf = $contrail::params::contrail_keystone_auth_conf,
    $contrail_collector_conf = $contrail::params::contrail_collector_conf,
    $contrail_query_engine_conf = $contrail::params::contrail_query_engine_conf,
    $contrail_snmp_collector_ini = $contrail::params::contrail_snmp_collector_ini,
) {

    # Main code for class
    case $::operatingsystem {
        Ubuntu: {
            file {'/etc/init/supervisor-analytics.override':
                ensure => absent
            } ->
            file { '/etc/init.d/supervisor-analytics':
                ensure => link,
                target => '/lib/init/upstart-job',
            }
        }
        default: { ## TODO 
        }
    }

    include ::contrail::keystone

    file { '/etc/snmp':
       ensure  => directory,
    } ->
    file { '/etc/snmp/snmp.conf':
      content => 'mibs +ALL'
    }
    ->
    file { '/etc/redis/redis.conf' :
        content => template("${module_name}/redis.conf.erb"),
    }


    validate_hash($contrail_topology_conf)
    validate_hash($contrail_alarm_gen_conf)
    validate_hash($contrail_snmp_collector_conf)
    validate_hash($contrail_analytics_nodemgr_conf)
    validate_hash($contrail_analytics_api_conf)
    validate_hash($contrail_collector_conf)
    validate_hash($contrail_query_engine_conf)
    validate_hash($contrail_snmp_collector_ini)

    create_resources(contrail_collector_config, $contrail_collector_conf)
    create_resources(contrail_query_engine_config, $contrail_query_engine_conf)
    create_resources(contrail_snmp_collector_ini_config, $contrail_snmp_collector_ini)
    create_resources(contrail_topology_config, $contrail_topology_conf)
    create_resources(contrail_alarm_gen_config, $contrail_alarm_gen_conf)
    create_resources(contrail_snmp_collector_config, $contrail_snmp_collector_conf)
    create_resources(contrail_analytics_nodemgr_config, $contrail_analytics_nodemgr_conf)
    create_resources(contrail_analytics_api_config, $contrail_analytics_api_conf)
}
