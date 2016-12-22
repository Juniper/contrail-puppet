# == Class: contrail::profile::openstack::ceilometer
# The puppet module to set up openstack::ceilometer for contrail
#
#
class contrail::profile::openstack::ceilometer (
  $openstack_verbose = $::contrail::params::os_verbose,
  $openstack_debug   = $::contrail::params::os_debug,
  $region_name       = $::contrail::params::os_region,
  $mongo_password    = $::contrail::params::os_mongo_password,
  $metering_secret   = $::contrail::params::os_metering_secret,
  $database_ip_list  = $::contrail::params::database_ip_list,
  $internal_vip      = $::contrail::params::internal_vip,
  $analytics_node_ip = $::contrail::params::collector_ip_to_use,
  $service_password  = $::contrail::params::os_mysql_service_password,
  $allowed_hosts     = $::contrail::params::os_mysql_allowed_hosts,
  $sync_db           = $::contrail::params::os_sync_db,
  $package_sku        = $::contrail::params::package_sku,
  $ceilometer_password        = $::contrail::params::os_ceilometer_password,
  $openstack_rabbit_servers   = $::contrail::params::openstack_rabbit_hosts,
  $openstack_rabbit_server_to_use   = $::contrail::params::openstack_rabbit_server_to_use,
  $openstack_rabbit_port      = $::contrail::params::rabbit_port_real,
  $controller_mgmt_address    = $::contrail::params::os_controller_mgmt_address,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
  $rabbit_use_ssl     = $::contrail::params::os_amqp_ssl,
  $kombu_ssl_ca_certs = $::contrail::params::kombu_ssl_ca_certs,
  $kombu_ssl_certfile = $::contrail::params::kombu_ssl_certfile,
  $kombu_ssl_keyfile  = $::contrail::params::kombu_ssl_keyfile,
  $keystone_version   = $::contrail::params::keystone_version
) {
  $database_ip_to_use = $database_ip_list[0]
  $mongo_connection = join([ "mongodb://ceilometer:", $mongo_password, "@", join($database_ip_list,':27017,') ,":27017/ceilometer?replicaSet=rs-ceilometer" ],'')
  $auth_url = "http://${keystone_ip_to_use}:5000/${keystone_version}"
  $auth_uri = "http://${keystone_ip_to_use}:5000"
  $auth_password = $ceilometer_password
  $auth_tenant_name = 'services'
  $auth_username = 'ceilometer'
  $rabbit_password = 'guest'
  $telemetry_secret = $metering_secret
  if (internal_vip!='') {
    $coordination_url = join(["kazoo://", $database_ip_to_use, ':2181'])
    Class['::ceilometer']->
    ceilometer_config {
      'notification/workload_partitioning' : value => 'True';
      'compute/workload_partitioning'      : value => 'True';
    }
  } else {
    $coordination_url = undef
  }

  if ($keystone_version == "v3" ) {
      $domain_name = 'Default'
  } else {
      $domain_name = ''
  }

  class { '::ceilometer::db':
    database_connection => $mongo_connection,
    sync_db             => $sync_db
  }

  class { '::ceilometer':
    metering_secret => $metering_secret,
    debug           => $openstack_verbose,
    verbose         => $openstack_debug,
    rabbit_host     => $openstack_rabbit_server_to_use,
    rabbit_port     => $openstack_rabbit_port,
    rabbit_use_ssl     => $rabbit_use_ssl,
    kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
    kombu_ssl_certfile => $kombu_ssl_certfile,
    kombu_ssl_keyfile  => $kombu_ssl_keyfile,
    rpc_backend        => 'rabbit',
    rabbit_password    => $rabbit_password
  } ->
  ceilometer_config {
    'database/time_to_live'      : value => '7200';
    'publisher/telemetry_secret' : value => $metering_secret;
    'DEFAULT/auth_strategy'      : value => 'keystone';
    'service_credentials/os_auth_url' : value => $auth_url;
    'service_credentials/os_username' : value => $auth_username;
    'service_credentials/os_password' : value => $auth_password;
    'service_credentials/os_tenant_name' : value => $auth_tenant_name;
  } ->
  class { '::ceilometer::agent::auth':
    auth_url         => $auth_url,
    auth_password    => $auth_password,
    auth_tenant_name => $auth_tenant_name,
    auth_user        => $auth_username,
    auth_project_domain_name => $domain_name,
    auth_user_domain_name => $domain_name
  } ->
  class { '::ceilometer::agent::central':
    coordination_url => $coordination_url
  }
  class { '::ceilometer::agent::notification':
  }

  # NOTE: Added a ordering here, creates dependcy cycle for HA case.
  class { '::ceilometer::collector': } ->
  file { '/etc/ceilometer/pipeline.yaml':
    ensure => file,
    content => template('contrail/pipeline.yaml.erb'),
  }

  case $package_sku {
    /13\.0/: {
      class { '::ceilometer::api':
        enabled           => true,
        keystone_auth_uri => $auth_url,
        keystone_password => $ceilometer_password,
        keystone_tenant   => $auth_tenant_name,
      }
    }

    default: {
      class { '::ceilometer::api':
        enabled           => true,
        auth_uri          => $auth_uri,
        keystone_host     => $keystone_ip_to_use,
        keystone_password => $ceilometer_password,
        keystone_tenant   => $auth_tenant_name,
      }
    }
  }
  if $::osfamily != 'Debian' {
    class { '::ceilometer::alarm::notifier':
    } ->
    class { '::ceilometer::alarm::evaluator':
      coordination_url => $coordination_url
    }
  }

}
