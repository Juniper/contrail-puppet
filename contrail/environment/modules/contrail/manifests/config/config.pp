class contrail::config::config (
    $host_control_ip = $::contrail::params::host_ip,
    $collector_ip = $::contrail::params::collector_ip_list[0],
    $database_ip_list = $::contrail::params::database_ip_list,
    $control_ip_list = $::contrail::params::control_ip_list,
    $openstack_ip = $::contrail::params::openstack_ip_list[0],
    $uuid = $::contrail::params::uuid,
    $keystone_ip = $::contrail::params::keystone_ip,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $use_certs = $::contrail::params::use_certs,
    $multi_tenancy = $::contrail::params::multi_tenancy,
    $zookeeper_ip_list = $::contrail::params::zk_ip_list_to_use,
    $quantum_port = $::contrail::params::quantum_port,
    $quantum_service_protocol = $::contrail::params::quantum_service_protocol,
    $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol,
    $keystone_auth_port = $::contrail::params::keystone_auth_port,
    $keystone_service_tenant = $::contrail::params::keystone_service_tenant,
    $keystone_insecure_flag = $::contrail::params::keystone_insecure_flag,
    $api_nworkers = $::contrail::params::api_nworkers,
    $haproxy = $::contrail::params::haproxy,
    $keystone_region_name = $::contrail::params::keystone_region_name,
    $manage_neutron = $::contrail::params::manage_neutron,
    $openstack_manage_amqp = $::contrail::params::openstack_manage_amqp,
    $amqp_server_ip = $::contrail::params::amqp_server_ip,
    $openstack_mgmt_ip = $::contrail::params::openstack_mgmt_ip_list_to_use[0],
    $internal_vip = $::contrail::params::internal_vip,
    $external_vip = $::contrail::params::external_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $contrail_plugin_location = $::contrail::params::contrail_plugin_location,
    $config_ip_list = $::contrail::params::config_ip_list,
    $config_name_list = $::contrail::params::config_name_list,
    $database_ip_port = $::contrail::params::database_ip_port,
    $zk_ip_port = $::contrail::params::zk_ip_port,
    $hc_interval = $::contrail::params::hc_interval,
    $vmware_ip = $::contrail::params::vmware_ip,
    $vmware_username = $::contrail::params::vmware_username,
    $vmware_password = $::contrail::params::vmware_password,
    $vmware_vswitch = $::contrail::params::vmware_vswitch,
    $config_ip = $::contrail::params::config_ip_to_use,
    $collector_ip = $::contrail::params::collector_ip_to_use,
    $vip = $::contrail::params::vip_to_use,
    $contrail_rabbit_servers= $::contrail::params::contrail_rabbit_servers,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    # Main code for class starts here
    if $use_certs == true {
      $ifmap_server_port = '8444'
    } else {
      $ifmap_server_port = '8443'
    }

    $analytics_api_port = '8081'
    $contrail_plugin_file = '/etc/neutron/plugins/opencontrail/ContrailPlugin.ini'
    $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use
    $amqp_server_ip_to_use = $::contrail::params::amqp_server_ip_to_use

    if $multi_tenancy == true {
        $memcached_opt = 'memcache_servers=127.0.0.1:11211'
    } else {
        $memcached_opt = ''
    }
    # Initialize the multi tenancy option will update latter based on vns argument
    if ($multi_tenancy == true) {
        $mt_options = 'admin,$keystone_admin_password,$keystone_admin_tenant'
    } else {
        $mt_options = 'None'
    }

    # Set params based on internval VIP being set

    if ($internal_vip != '') {
        $rabbit_server_to_use = $internal_vip
        $rabbit_port_to_use = 5673
    } else {
        $rabbit_server_to_use = $host_control_ip
        $rabbit_port_to_use = 5672
    }
    $controller_ip = $keystone_ip_to_use
    # Supervisor contrail-api.ini
    $api_port_base = '910'
    # Supervisor contrail-discovery.ini
    $disc_port_base = '911'

    $contrail_api_ubuntu_command = join(["/usr/bin/contrail-api --conf_file /etc/contrail/contrail-api.conf --conf_file /etc/contrail/contrail-keystone-auth.conf --listen_port ",$api_port_base,"%(process_num)01d --worker_id %(process_num)s"],'')
    $contrail_discovery_ubuntu_command = join(["/usr/bin/contrail-discovery --conf_file /etc/contrail/contrail-discovery.conf --listen_port ",$disc_port_base,"%(process_num)01d --worker_id %(process_num)s"],'')
    $contrail_api_centos_command = join(['/bin/bash -c "source /opt/contrail/api-venv/bin/activate && exec python /opt/contrail/api-venv/lib/python2.7/site-packages/vnc_cfg_api_server/vnc_cfg_api_server.py --conf_file /etc/contrail/contrail-api.conf --listen_port ',$api_port_base,'%(process_num)01d --worker_id %(process_num)s"'],'')
    $contrail_discovery_centos_command = join(['/bin/bash -c "source /opt/contrail/api-venv/bin/activate && exec python /opt/contrail/api-venv/lib/python2.7/site-packages/discovery/disc_server_zk.py --conf_file /etc/contrail/contrail-discovery.conf --listen_port ',$disc_port_base,'%(process_num)01d --worker_id %(process_num)s"'],'')


    $keystone_auth_server = $keystone_ip_to_use
    $disc_nworkers = $api_nworkers
    $discovery_ip_to_use =  $::contrail::params::discovery_ip_to_use

    $database_ip_port_list = suffix($database_ip_list, ":$database_ip_port")
    $cassandra_server_list = join($database_ip_port_list, ' ' )

    $zk_ip_port_to_use = suffix($zookeeper_ip_list, ":$zk_ip_port")
    $zk_ip_port_list = join($zk_ip_port_to_use, ',')
    $zk_ip_list = join($zookeeper_ip_list, ',')

    $keystone_auth_url = join([$keystone_auth_protocol,"://",$keystone_ip_to_use,":",$keystone_auth_port,"/v2.0"],'')

    # Set number of config nodes
    $cfgm_number = size($config_ip_list)

    File {
      ensure => 'present'
    }

    $cfgm_ip_list_shell = join($config_ip_list,",")
    $cfgm_name_list_shell = join($config_name_list, ",")

    $rabbit_env = "NODE_IP_ADDRESS=${host_control_ip}\nNODENAME=rabbit@${::hostname}ctl\n"

    case $::operatingsystem {
        Ubuntu: {
            $api_command_to_use = $contrail_api_ubuntu_command
            $discovery_command_to_use = $contrail_discovery_ubuntu_command
        }
        'Centos', 'Fedora' : {
            # notify { "OS is Ubuntu":; }
            $api_command_to_use = $contrail_api_centos_command
            $discovery_command_to_use = $contrail_discovery_centos_command
        }
        default: {
        # notify { "OS is $operatingsystem":; }
        }
    }
    $log4j_properties_file = '/etc/ifmap-server/log4j.properties'
    $log4j_properties_config = { 'log4j_properties' => {
         'log4j.rootLogger' => "TRACE, CONSOLE",
         'log4j.logger.de.fhhannover.inform.irond.proc' => "TRACE, A1, A2",
         'log4j.additivity.de.fhhannover.inform.irond.proc' => 'false',
         'log4j.appender.A1' => 'org.apache.log4j.ConsoleAppender',
         'log4j.appender.A1.layout' => 'org.apache.log4j.PatternLayout',
         'log4j.appender.A1.layout.ConversionPattern' => "%d [%t] %-5p %x - %m%n",
         'log4j.appender.A2' => 'org.apache.log4j.FileAppender',
         'log4j.appender.A2.File' => '/var/log/contrail/ifmap-server.log',
         'log4j.appender.A2.layout' => 'org.apache.log4j.PatternLayout',
         'log4j.appender.A2.layout.ConversionPattern' => "%d [%t] %-5p %x - %m%n",
         'log4j.logger.de.fhhannover.inform.irond.rawrequests' => "TRACE, A3",
         'log4j.additivity.de.fhhannover.inform.irond.rawrequests' => 'false',
         'log4j.appender.A3' => 'org.apache.log4j.FileAppender',
         'log4j.appender.A3.file' => 'irond_raw.log',
         'log4j.appender.A3.layout' => 'org.apache.log4j.PatternLayout',
         'log4j.appender.A3.layout.ConversionPattern' => "%d %-5p %x - %m%n",
         'log4j.appender.CONSOLE' => 'org.apache.log4j.ConsoleAppender',
         'log4j.appender.CONSOLE.layout' => 'org.apache.log4j.PatternLayout',
         'log4j.appender.CONSOLE.layout.ConversionPattern' => "%-8r [%t] %-5p %C{1} %x - %m%n",
        },
    }
    $log4j_augeas_lens_to_use = 'properties.lns'
    $authorizaion_properties_file = '/etc/ifmap-server/authorization.properties'
    $authorizaion_properties_config = { 'authorizaion_properties' => {'reader' => 'ro',},}
    $authorizaion_augeas_lens_to_use = 'properties.lns'
    $publisher_properties_file = '/etc/ifmap-server/publisher.properties'
    $publisher_properties_config = { 'publisher_properties' => {
         'visual' => 'visual--1877135140-1',
         'test' => 'test--1870931913-1',
         'test2' => 'test2--1870931914-1',
         'test3' => 'test3--1870931915-1',
         'api-server' => 'api-server-1--0000000001-1',
         'control-node-1' => 'control-node-1--1870931921-1',
         'control-node-2' => 'control-node-1--1870931922-1',
         'control-node-3' => 'control-node-1--1870931923-1',
         'control-node-4' => 'control-node-1--1870931924-1',
         'control-node-5' => 'control-node-1--1870931925-1',
         'control-node-6' => 'control-node-1--1870931926-1',
         'control-node-7' => 'control-node-1--1870931927-1',
         'control-node-8' => 'control-node-1--1870931928-1',
         'control-node-9' => 'control-node-1--1870931929-1',
         'control-node-10' => 'control-node-10--1870931930-1',
        },
    }
    $publisher_augeas_lens_to_use = 'properties.lns'

    $config_sysctl_settings = {
      'net.ipv4.tcp_keepalive_time' => { value => 5 },
      'net.ipv4.tcp_keepalive_probes' => { value => 5 },
      'net.ipv4.tcp_keepalive_intvl' => { value => 1 },
    }
    create_resources(sysctl::value, $config_sysctl_settings, {} )
    contrail_api_ini {
            'program:contrail-api/command'      : value => "$api_command_to_use";
            'program:contrail-api/numprocs'     : value => "$api_nworkers";
            'program:contrail-api/process_name' : value => '%(process_num)s';
            'program:contrail-api/redirect_stderr' : value => 'true';
            'program:contrail-api/stdout_logfile' : value => '/var/log/contrail/contrail-api-%(process_num)s.log';
            'program:contrail-api/stderr_logfile' : value => '/dev/null';
            'program:contrail-api/priority' : value => '440';
            'program:contrail-api/autostart' : value => 'true';
            'program:contrail-api/killasgroup' : value => 'true';
            'program:contrail-api/stopsignal' : value => 'KILL';
    } ->
    contrail_discovery_ini {
             'program:contrail-discovery/command'      : value => "$discovery_command_to_use";
             'program:contrail-discovery/numprocs'     : value => "$disc_nworkers";
             'program:contrail-discovery/process_name' : value => '%(process_num)s';
             'program:contrail-discovery/redirect_stderr' : value => 'true';
             'program:contrail-discovery/stdout_logfile' : value => '/var/log/contrail/contrail-discovery-%(process_num)s.log';
             'program:contrail-discovery/stderr_logfile' : value => '/dev/null';
             'program:contrail-discovery/priority' : value => '430';
             'program:contrail-discovery/autostart' : value => 'true';
             'program:contrail-discovery/killasgroup' : value => 'true';
             'program:contrail-discovery/stopsignal' : value => 'KILL';
    } ->
    #set rpc backend in neutron.conf
    contrail::lib::augeas_conf_rm { "config_neutron_rpc_backend":
        key => 'rpc_backend',
        config_file => '/etc/neutron/neutron.conf',
        lens_to_use => 'properties.lns',
        match_value => 'neutron.openstack.common.rpc.impl_qpid',
    } ->
    #form the sudoers
    file { '/etc/sudoers.d/contrail_sudoers' :
        mode   => '0440',
        group  => root,
        source => "puppet:///modules/${module_name}/contrail_sudoers"
    } ->
    # Ensure log4j.properties file is present with right content.
    contrail::lib::augeas_conf_set { 'log4j_properties_keys':
            config_file => $log4j_properties_file,
            settings_hash => $log4j_properties_config['log4j_properties'],
            lens_to_use => $log4j_augeas_lens_to_use,
    } ->
    contrail::lib::augeas_conf_rm { 'remove_key_log4j.appender.A1.File':
            key => 'log4j.appender.A1.File',
            config_file => $log4j_properties_file,
            lens_to_use => $log4j_augeas_lens_to_use,
    } ->

    # Ensure authorization.properties file is present with right content.
    contrail::lib::augeas_conf_set { 'authorizaion_properties_keys':
            config_file => $authorizaion_properties_file,
            settings_hash => $authorizaion_properties_config['authorizaion_properties'],
            lens_to_use => $authorizaion_augeas_lens_to_use,
    } ->

    # Ensure basicauthusers.proprties file is present with right content.
    file { '/etc/ifmap-server/basicauthusers.properties' :
        content => template("${module_name}/basicauthusers.properties.erb"),
    } ->

    # Ensure publisher.properties file is present with right content.
    contrail::lib::augeas_conf_set { 'publisher_properties_keys':
            config_file => $publisher_properties_file,
            settings_hash => $publisher_properties_config['publisher_properties'],
            lens_to_use => $publisher_augeas_lens_to_use,
    } ->
    # Ensure all config files with correct content are present.
    contrail_api_config {
        'DEFAULTS/ifmap_server_ip'      : value => "$host_control_ip";
        'DEFAULTS/ifmap_server_port'    : value => "$ifmap_server_port";
        'DEFAULTS/ifmap_username'       : value => 'api-server';
        'DEFAULTS/ifmap_password'       : value => 'api-server';
        'DEFAULTS/cassandra_server_list': value => "$cassandra_server_list";
        'DEFAULTS/listen_ip_addr'       : value => '0.0.0.0';
        'DEFAULTS/listen_port'          : value => '8082';
        'DEFAULTS/auth'                 : value => 'keystone';
        'DEFAULTS/multi_tenancy'        : value => "$multi_tenancy";
        'DEFAULTS/log_file'             : value => '/var/log/contrail/api.log';
        'DEFAULTS/log_local'            : value => '1';
        'DEFAULTS/log_level'            : value => 'SYS_NOTICE';
        'DEFAULTS/disc_server_ip'       : value => "$config_ip";
        'DEFAULTS/disc_server_port'     : value => '5998';
        'DEFAULTS/zk_server_ip'         : value => "$zk_ip_port_list";
        'DEFAULTS/rabbit_server'        : value => "$contrail_rabbit_servers";
        'SECURITY/use_certs'            : value => "$use_certs";
        'SECURITY/keyfile'              : value => '/etc/contrail/ssl/private_keys/apiserver_key.pem';
        'SECURITY/certfile'             : value => '/etc/contrail/ssl/certs/apiserver.pem';
        'SECURITY/ca_certs'             : value => '/etc/contrail/ssl/certs/ca.pem';
    } ->
    contrail_config_nodemgr_config {
        'DISCOVERY/server'     : value => "$config_ip";
        'DISCOVERY/port'     : value => '5998';
    } ->
    contrail_schema_config {
        'DEFAULTS/ifmap_server_ip'      : value => "$host_control_ip";
        'DEFAULTS/ifmap_server_port'    : value => "$ifmap_server_port";
        'DEFAULTS/ifmap_username'       : value => 'schema-transformer';
        'DEFAULTS/ifmap_password'       : value => 'schema-transformer';
        'DEFAULTS/api_server_ip'        : value => "$config_ip";
        'DEFAULTS/api_server_port'      : value => '8082';
        'DEFAULTS/zk_server_ip'         : value => "$zk_ip_port_list";
        'DEFAULTS/log_file'             : value => '/var/log/contrail/schema.log';
        'DEFAULTS/cassandra_server_list': value => "$cassandra_server_list";
        'DEFAULTS/disc_server_ip'       : value => "$config_ip";
        'DEFAULTS/disc_server_port'     : value => '5998';
        'DEFAULTS/log_local'            : value => '1';
        'DEFAULTS/log_level'            : value => 'SYS_NOTICE';
        'DEFAULTS/rabbit_server'        : value => "$contrail_rabbit_servers";
        'SECURITY/use_certs'            : value => "$use_certs";
        'SECURITY/keyfile'              : value => '/etc/contrail/ssl/private_keys/schema_xfer_key.pem';
        'SECURITY/certfile'             : value => '/etc/contrail/ssl/certs/schema_xfer.pem';
        'SECURITY/ca_certs'             : value => '/etc/contrail/ssl/certs/ca.pem';
    } ->
    contrail_svc_monitor_config {
         'DEFAULTS/ifmap_server_ip'      : value => "$host_control_ip";
         'DEFAULTS/ifmap_server_port'    : value => "$ifmap_server_port";
         'DEFAULTS/ifmap_username'       : value => 'svc-monitor';
         'DEFAULTS/ifmap_password'       : value => 'svc-monitor';
         'DEFAULTS/api_server_ip'        : value => "$config_ip";
         'DEFAULTS/api_server_port'      : value => '8082';
         'DEFAULTS/zk_server_ip'         : value => "$zk_ip_port_list";
         'DEFAULTS/log_file'             : value => '/var/log/contrail/svc-monitor.log';
         'DEFAULTS/cassandra_server_list': value => "$cassandra_server_list";
         'DEFAULTS/disc_server_ip'       : value => "$config_ip";
         'DEFAULTS/disc_server_port'     : value => '5998';
         'DEFAULTS/region_name'          : value => "$keystone_region_name";
         'DEFAULTS/log_local'            : value => '1';
         'DEFAULTS/log_level'            : value => 'SYS_NOTICE';
         'DEFAULTS/rabbit_server'        : value => "$contrail_rabbit_servers";
         'SECURITY/use_certs'            : value => "$use_certs";
         'SECURITY/keyfile'              : value => '/etc/contrail/ssl/private_keys/svc_monitor_key.pem';
         'SECURITY/certfile'             : value => '/etc/contrail/ssl/certs/svc_monitor.pem';
         'SECURITY/ca_certs'             : value => '/etc/contrail/ssl/certs/ca.pem';
         'SCHEDULER/analytics_server_ip' : value => "$collector_ip";
         'SCHEDULER/analytics_server_port': value => '8081';
    } ->
    contrail_device_manager_config {
        'DEFAULTS/rabbit_server'        : value => "$contrail_rabbit_servers";
        'DEFAULTS/api_server_ip'        : value => "$config_ip";
        'DEFAULTS/disc_server_ip'       : value => "$config_ip";
        'DEFAULTS/api_server_port'      : value => '8082';
        'DEFAULTS/zk_server_ip'         : value => "$zk_ip_port_list";
        'DEFAULTS/log_file'             : value => '/var/log/contrail/contrail-device-manager.log';
        'DEFAULTS/cassandra_server_list': value => "$cassandra_server_list";
        'DEFAULTS/disc_server_port'     : value => '5998';
        'DEFAULTS/log_local'            : value => '1';
        'DEFAULTS/log_level'            : value => 'SYS_NOTICE';
    } ->
    contrail_discovery_config {
        'DEFAULTS/zk_server_ip'         : value => "$zk_ip_list";
        'DEFAULTS/zk_server_port'       : value => '2181';
        'DEFAULTS/listen_ip_addr'       : value => '0.0.0.0';
        'DEFAULTS/listen_port'          : value => '5998';
        'DEFAULTS/log_local'            : value => 'True';
        'DEFAULTS/log_file'             : value => '/var/log/contrail/contrail-discovery.log';
        'DEFAULTS/cassandra_server_list': value => "$cassandra_server_list";
        'DEFAULTS/log_level'            : value => 'SYS_NOTICE';
        'DEFAULTS/ttl_min'              : value => '300';
        'DEFAULTS/ttl_max'              : value => '1800';
        'DEFAULTS/hc_interval'          : value => "$hc_interval";
        'DEFAULTS/hc_max_miss'          : value => '3';
        'DEFAULTS/ttl_short'            : value => '1';
        'DNS-SERVER/policy'             : value => 'fixed';
    } ->
    contrail_vnc_api_config {
        'global/WEB_SERVER'             : value => '127.0.0.1';
        'global/WEB_PORT'               : value => '8082';
        'global/BASE_URL'               : value => '/';
        'auth/AUTHN_TYPE'               : value => 'keystone';
        'auth/AUTHN_PROTOCOL'           : value => "$keystone_auth_protocol";
        'auth/AUTHN_SERVER'             : value => "$keystone_auth_server";
        'auth/AUTHN_PORT'               : value => '35357';
        'auth/AUTHN_URL'                : value => '/v2.0/tokens';
    } ->
    contrail_plugin_ini {
        'APISERVER/api_server_ip'   : value => "$config_ip";
        'APISERVER/api_server_port' : value => '8082';
        'APISERVER/multi_tenancy'   : value => "$multi_tenancy";
        'APISERVER/contrail_extensions': value => 'ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam,policy:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_policy.NeutronPluginContrailPolicy,route-table:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_vpc.NeutronPluginContrailVpc,contrail:None,service-interface:None,vf-binding:None';
        'KEYSTONE/auth_url'         : value => "$keystone_auth_url";
        'KEYSTONE/auth_user'        : value => "$keystone_admin_user";
        'KEYSTONE/admin_tenant_name': value => "$keystone_admin_tenant";
    } ->
    # initd script wrapper for contrail-api
    file { '/etc/init.d/contrail-api' :
        mode    => '0777',
        content => template("${module_name}/contrail-api.svc.erb"),
    } ->
    # contrail plugin for opencontrail
    opencontrail_plugin_ini {
        'APISERVER/api_server_ip'   : value => "$config_ip";
        'APISERVER/api_server_port' : value => '8082';
        'APISERVER/multi_tenancy'   : value => "$multi_tenancy";
        'APISERVER/contrail_extensions': value => 'ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam,policy:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_policy.NeutronPluginContrailPolicy,route-table:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_vpc.NeutronPluginContrailVpc,contrail:None';
        'KEYSTONE/auth_url'         : value => "$keystone_auth_url";
        'KEYSTONE/auth_user'        : value => "$keystone_admin_user";
        'KEYSTONE/admin_tenant_name': value => "$keystone_admin_tenant";
        'COLLECTOR/analytics_api_ip': value => "$collector_ip";
        'COLLECTOR/analytics_api_port': value => "$analytics_api_port";
    } ->
    contrail::lib::augeas_conf_set { 'NEUTRON_PLUGIN_CONFIG':
        config_file => '/etc/default/neutron-server',
        settings_hash => { 'NEUTRON_PLUGIN_CONFIG' => $contrail_plugin_location, },
        lens_to_use => 'properties.lns',
    } ->

    Class['::contrail::config::config_neutron_server'] ->

    # initd script wrapper for contrail-discovery
    file { '/etc/init.d/contrail-discovery' :
        mode    => '0777',
        content => template("${module_name}/contrail-discovery.svc.erb"),
    } ->

    Class['::contrail::config::rabbitmq'] ->

    file { '/usr/bin/nodejs':
        ensure => link,
        target => '/usr/bin/node',
    } ->

    Sysctl::Value['net.ipv4.tcp_keepalive_time']
    # run setup-pki.sh script
    if $use_certs == true {
         contain ::contrail::config::setup_pki
         Class['::contrail::config::rabbitmq']->Class['::contrail::config::setup_pki']->File['/usr/bin/nodejs']
    }
    contain ::contrail::openstackrc
    contain ::contrail::keystone
    contain ::contrail::config::config_neutron_server
    contain ::contrail::config::rabbitmq
    contain ::contrail::config::setup_quantum_server_setup
}
