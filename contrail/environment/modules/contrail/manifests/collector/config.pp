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

    if $::multi_tenancy == true {
        $memcached_opt = 'memcache_servers=127.0.0.1:11211'
    } else {
        $memcached_opt = ''
    }

    if ! defined(File['/etc/contrail/contrail-keystone-auth.conf']) {
        file { '/etc/contrail/contrail-keystone-auth.conf' :
            content => template("${module_name}/contrail-keystone-auth.conf.erb"),
        }
    }

    # Ensure all config files with correct content are present.
    file { '/etc/contrail/contrail-analytics-api.conf' :
        content => template("${module_name}/contrail-analytics-api.conf.erb"),
    }
    ->
    file { '/etc/contrail/contrail-collector.conf' :
        content => template("${module_name}/contrail-collector.conf.erb"),
    }
    ->
    file { '/etc/contrail/contrail-query-engine.conf' :
        content => template("${module_name}/contrail-query-engine.conf.erb"),
    }
    ->
    file { '/etc/contrail/contrail-snmp-collector.conf' :
        content => template("${module_name}/contrail-snmp-collector.conf.erb")
    }
    ->
    file { '/etc/contrail/supervisord_analytics_files/contrail-snmp-collector.ini' :
        content => template("${module_name}/contrail-snmp-collector.ini.erb"),
    }
    ->
  file { '/etc/snmp':
     ensure  => directory,
  } ->
  file { '/etc/snmp/snmp.conf':
    content => 'mibs +ALL'
  }
    ->
    file { '/etc/contrail/contrail-analytics-nodemgr.conf' :
        content => template("${module_name}/contrail-analytics-nodemgr.conf.erb"),
    }
    ->
    file { "/etc/contrail/contrail-alarm-gen.conf" :
        ensure  => present,
        content => template("$module_name/contrail-alarm-gen.conf.erb"),
    }
    ->
    file { '/etc/contrail/contrail-topology.conf' :
        content => template("${module_name}/contrail-topology.conf.erb"),
    }
    ->
    file { '/etc/redis/redis.conf' :
        content => template("${module_name}/redis.conf.erb"),
    }
}
