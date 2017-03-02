class contrail::config::config (
  $host_control_ip = $::contrail::params::host_ip,
  $collector_ip = $::contrail::params::collector_ip_list[0],
  $collector_ip_port_list = $::contrail::params::collector_ip_port_list,
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
  $host_roles = $::contrail::params::host_roles,
  $config_manage_db = $::contrail::params::config_manage_db,
  $rabbit_use_ssl     = $::contrail::params::contrail_amqp_ssl,
  $kombu_ssl_ca_certs = $::contrail::params::kombu_ssl_ca_certs,
  $kombu_ssl_certfile = $::contrail::params::kombu_ssl_certfile,
  $kombu_ssl_keyfile  = $::contrail::params::kombu_ssl_keyfile,
  $keystone_version   = $::contrail::params::keystone_version,
) {
  # Main code for class starts here

  if (!('database' in $host_roles) and $config_manage_db == true) {
    $database_ip_list_to_use = $config_ip_list
    Class['::contrail::config::database_install'] ->
    Class['::contrail::config::database'] ~>
    Class['::contrail::config::database_service']
    contain ::contrail::config::database_install
    contain ::contrail::config::database
    contain ::contrail::config::database_service
  } else {
    $database_ip_list_to_use = $database_ip_list
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

  if ($keystone_version == "v3" ) {
    $authn_url = "/v3/auth/tokens"
  } else {
    $authn_url = "/v2.0/tokens"
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
  $contrail_api_centos_command = join(["/usr/bin/contrail-api --conf_file /etc/contrail/contrail-api.conf --conf_file /etc/contrail/contrail-keystone-auth.conf --conf_file /etc/contrail/contrail-database.conf --listen_port ",$api_port_base,"%(process_num)01d --worker_id %(process_num)s"],'')
  $contrail_discovery_centos_command = join(["/usr/bin/contrail-discovery --conf_file /etc/contrail/contrail-discovery.conf --listen_port ",$disc_port_base,"%(process_num)01d --worker_id %(process_num)s"],'')


  $keystone_auth_server = $keystone_ip_to_use
  $disc_nworkers = $api_nworkers
  $discovery_ip_to_use =  $::contrail::params::discovery_ip_to_use

  $database_ip_port_list = suffix($database_ip_list_to_use, ":$database_ip_port")
  $cassandra_server_list = join($database_ip_port_list, ' ' )

  $zk_ip_port_to_use = suffix($zookeeper_ip_list, ":$zk_ip_port")
  $zk_ip_port_list = join($zk_ip_port_to_use, ',')
  $zk_ip_list = join($zookeeper_ip_list, ',')

  $keystone_auth_url = join([$keystone_auth_protocol,"://",$keystone_ip_to_use,":",$keystone_auth_port,"/", $keystone_version],'')

  # Set number of config nodes
  $cfgm_number = size($config_ip_list)

  File {
    ensure => 'present'
  }

  $cfgm_ip_list_shell = join($config_ip_list,",")
  $cfgm_name_list_shell = join($config_name_list, ",")

  case $::operatingsystem {
    Ubuntu: {
      $api_command_to_use = $contrail_api_ubuntu_command
      $discovery_command_to_use = $contrail_discovery_ubuntu_command
    }
    'Centos', 'Fedora' : {
      $api_command_to_use = $contrail_api_centos_command
      $discovery_command_to_use = $contrail_discovery_centos_command
    }
  }

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
    'program:contrail-api/redirect_stderr' : value => "true";
    'program:contrail-api/stdout_logfile' : value => '/var/log/contrail/contrail-api-%(process_num)s.log';
    'program:contrail-api/stderr_logfile' : value => '/dev/null';
    'program:contrail-api/priority' : value => '440';
    'program:contrail-api/autostart' : value => "true";
    'program:contrail-api/killasgroup' : value => "true";
    'program:contrail-api/stopsignal' : value => 'TERM';
  } ->
  contrail_discovery_ini {
    'program:contrail-discovery/command'      : value => "$discovery_command_to_use";
    'program:contrail-discovery/numprocs'     : value => "$disc_nworkers";
    'program:contrail-discovery/redirect_stderr' : value => "true";
    'program:contrail-discovery/stdout_logfile' : value => '/var/log/contrail/contrail-discovery-%(process_num)s.log';
    'program:contrail-discovery/stderr_logfile' : value => '/dev/null';
    'program:contrail-discovery/priority' : value => '430';
    'program:contrail-discovery/autostart' : value => "true";
    'program:contrail-discovery/autorestart' : value => "true";
    'program:contrail-discovery/killasgroup' : value => "true";
    'program:contrail-discovery/stopsignal' : value => 'TERM';
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

  # Ensure all config files with correct content are present.
  contrail_api_config {
    'DEFAULTS/cassandra_server_list': value => "$cassandra_server_list";
    'DEFAULTS/listen_ip_addr'       : value => '0.0.0.0';
    'DEFAULTS/listen_port'          : value => '8082';
    'DEFAULTS/auth'                 : value => 'keystone';
    'DEFAULTS/multi_tenancy'        : value => "$multi_tenancy";
    'DEFAULTS/log_file'             : value => '/var/log/contrail/api.log';
    'DEFAULTS/log_local'            : value => '1';
    'DEFAULTS/log_level'            : value => 'SYS_NOTICE';
    'DEFAULTS/zk_server_ip'         : value => "$zk_ip_port_list";
    'DEFAULTS/rabbit_server'        : value => "$contrail_rabbit_servers";
    'DEFAULTS/rabbit_use_ssl'       : value => $rabbit_use_ssl;
    'DEFAULTS/kombu_ssl_ca_certs'   : value => $kombu_ssl_ca_certs;
    'DEFAULTS/kombu_ssl_certfile'   : value => $kombu_ssl_certfile;
    'DEFAULTS/kombu_ssl_keyfile'    : value => $kombu_ssl_keyfile;
    'DEFAULTS/collectors'           : value => $collector_ip_port_list;
    'SECURITY/use_certs'            : value => "$use_certs";
    'SECURITY/keyfile'              : value => '/etc/contrail/ssl/private_keys/apiserver_key.pem';
    'SECURITY/certfile'             : value => '/etc/contrail/ssl/certs/apiserver.pem';
    'SECURITY/ca_certs'             : value => '/etc/contrail/ssl/certs/ca.pem';
  } ->
  contrail_config_nodemgr_config {
    'COLLECTOR/server_list': value => $collector_ip_port_list;
  } ->
  contrail_schema_config {
    'DEFAULTS/api_server_ip'        : value => "$config_ip";
    'DEFAULTS/api_server_port'      : value => '8082';
    'DEFAULTS/zk_server_ip'         : value => "$zk_ip_port_list";
    'DEFAULTS/log_file'             : value => '/var/log/contrail/schema.log';
    'DEFAULTS/cassandra_server_list': value => "$cassandra_server_list";
    'DEFAULTS/log_local'            : value => '1';
    'DEFAULTS/log_level'            : value => 'SYS_NOTICE';
    'DEFAULTS/rabbit_server'        : value => "$contrail_rabbit_servers";
    'DEFAULTS/rabbit_use_ssl'       : value => $rabbit_use_ssl;
    'DEFAULTS/kombu_ssl_ca_certs'   : value => $kombu_ssl_ca_certs;
    'DEFAULTS/kombu_ssl_certfile'   : value => $kombu_ssl_certfile;
    'DEFAULTS/kombu_ssl_keyfile'    : value => $kombu_ssl_keyfile;
    'DEFAULTS/collectors'           : value => $collector_ip_port_list;
    'SECURITY/use_certs'            : value => "$use_certs";
    'SECURITY/keyfile'              : value => '/etc/contrail/ssl/private_keys/schema_xfer_key.pem';
    'SECURITY/certfile'             : value => '/etc/contrail/ssl/certs/schema_xfer.pem';
    'SECURITY/ca_certs'             : value => '/etc/contrail/ssl/certs/ca.pem';
  } ->
  contrail_svc_monitor_config {
    'DEFAULTS/api_server_ip'        : value => "$config_ip";
    'DEFAULTS/api_server_port'      : value => '8082';
    'DEFAULTS/zk_server_ip'         : value => "$zk_ip_port_list";
    'DEFAULTS/log_file'             : value => '/var/log/contrail/svc-monitor.log';
    'DEFAULTS/cassandra_server_list': value => "$cassandra_server_list";
    'DEFAULTS/region_name'          : value => "$keystone_region_name";
    'DEFAULTS/log_local'            : value => '1';
    'DEFAULTS/log_level'            : value => 'SYS_NOTICE';
    'DEFAULTS/rabbit_server'        : value => "$contrail_rabbit_servers";
    'DEFAULTS/rabbit_use_ssl'       : value => $rabbit_use_ssl;
    'DEFAULTS/kombu_ssl_ca_certs'   : value => $kombu_ssl_ca_certs;
    'DEFAULTS/kombu_ssl_certfile'   : value => $kombu_ssl_certfile;
    'DEFAULTS/kombu_ssl_keyfile'    : value => $kombu_ssl_keyfile;
    'DEFAULTS/collectors'           : value => $collector_ip_port_list;
    'SECURITY/use_certs'            : value => "$use_certs";
    'SECURITY/keyfile'              : value => '/etc/contrail/ssl/private_keys/svc_monitor_key.pem';
    'SECURITY/certfile'             : value => '/etc/contrail/ssl/certs/svc_monitor.pem';
    'SECURITY/ca_certs'             : value => '/etc/contrail/ssl/certs/ca.pem';
    'SCHEDULER/analytics_server_ip' : value => "$collector_ip";
    'SCHEDULER/analytics_server_port': value => '8081';
  } ->
  contrail_device_manager_config {
    'DEFAULTS/rabbit_server'        : value => "$contrail_rabbit_servers";
    'DEFAULTS/rabbit_use_ssl'       : value => $rabbit_use_ssl;
    'DEFAULTS/kombu_ssl_ca_certs'   : value => $kombu_ssl_ca_certs;
    'DEFAULTS/kombu_ssl_certfile'   : value => $kombu_ssl_certfile;
    'DEFAULTS/kombu_ssl_keyfile'    : value => $kombu_ssl_keyfile;
    'DEFAULTS/api_server_ip'        : value => "$config_ip";
    'DEFAULTS/zk_server_ip'         : value => "$zk_ip_port_list";
    'DEFAULTS/log_file'             : value => '/var/log/contrail/contrail-device-manager.log';
    'DEFAULTS/cassandra_server_list': value => "$cassandra_server_list";
    'DEFAULTS/log_local'            : value => '1';
    'DEFAULTS/log_level'            : value => 'SYS_NOTICE';
    'DEFAULTS/collectors'           : value => "$collector_ip_port_list";
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
    'DEFAULTS/collectors'           : value => $collector_ip_port_list;
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
    'auth/AUTHN_URL'                : value => $authn_url;
  } ->
  contrail_plugin_ini {
    'APISERVER/api_server_ip'   : value => "$config_ip";
    'APISERVER/api_server_port' : value => '8082';
    'APISERVER/multi_tenancy'   : value => "$multi_tenancy";
    'APISERVER/contrail_extensions': value => 'ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam,policy:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_policy.NeutronPluginContrailPolicy,route-table:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_vpc.NeutronPluginContrailVpc,contrail:None,service-interface:None,vf-binding:None';
    'KEYSTONE/auth_url'         : value => "$keystone_auth_url";
    'KEYSTONE/admin_user'        : value => "$keystone_admin_user";
    'KEYSTONE/admin_password'    : value => "$keystone_admin_password";
    'KEYSTONE/auth_user'        : value => "$keystone_admin_user";
    'KEYSTONE/admin_tenant_name': value => "$keystone_admin_tenant";
  } ->
  # contrail plugin for opencontrail
  opencontrail_plugin_ini {
    'APISERVER/api_server_ip'   : value => "$config_ip";
    'APISERVER/api_server_port' : value => '8082';
    'APISERVER/multi_tenancy'   : value => "$multi_tenancy";
    'APISERVER/contrail_extensions': value => 'ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam,policy:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_policy.NeutronPluginContrailPolicy,route-table:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_vpc.NeutronPluginContrailVpc,contrail:None';
    'KEYSTONE/auth_url'         : value => "$keystone_auth_url";
    'KEYSTONE/admin_user'        : value => "$keystone_admin_user";
    'KEYSTONE/admin_password'    : value => "$keystone_admin_password";
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

  #Class['::contrail::config::config_neutron_server'] ->

  file { '/usr/bin/nodejs':
    ensure => link,
    target => '/usr/bin/node',
  } ->
  Sysctl::Value['net.ipv4.tcp_keepalive_time']
  if (! defined(Class['::contrail::rabbitmq'])){
    contain ::contrail::rabbitmq
    Contrail::Lib::Augeas_conf_set['NEUTRON_PLUGIN_CONFIG']->Class['::contrail::rabbitmq']->File['/usr/bin/nodejs']
  }
  # run setup-pki.sh script
  if $use_certs == true {
    contain ::contrail::config::setup_pki
    Contrail::Lib::Augeas_conf_set['NEUTRON_PLUGIN_CONFIG']->Class['::contrail::config::setup_pki']->File['/usr/bin/nodejs']
  }
  contain ::contrail::openstackrc
  contain ::contrail::keystone
  #contain ::contrail::config::config_neutron_server
  contain ::contrail::config::setup_quantum_server_setup
}
