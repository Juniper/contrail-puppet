class contrail::collector::config (
    $redis_password = $::contrail::params::redis_password,
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
