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
  $package_sku        = $::contrail::params::package_sku,
  $ceilometer_password        = $::contrail::params::os_ceilometer_password,
  $openstack_rabbit_servers   = $::contrail::params::openstack_rabbit_hosts,
  $controller_mgmt_address    = $::contrail::params::os_controller_mgmt_address,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
  $rabbit_use_ssl     = $::contrail::params::os_amqp_ssl,
  $kombu_ssl_ca_certs = $::contrail::params::kombu_ssl_ca_certs,
  $kombu_ssl_certfile = $::contrail::params::kombu_ssl_certfile,
  $kombu_ssl_keyfile  = $::contrail::params::kombu_ssl_keyfile,
) {
  $database_ip_to_use = $database_ip_list[0]
  $mongo_connection = join([ "mongodb://ceilometer:", $mongo_password, "@", join($database_ip_list,':27017,') ,":27017/ceilometer?replicaSet=rs-ceilometer" ],'')
  $auth_url = "http://${keystone_ip_to_use}:5000/v2.0"
  $auth_password = $ceilometer_password
  $auth_tenant_name = 'services'
  $auth_username = 'ceilometer'
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

  class { '::ceilometer':
    metering_secret => $metering_secret,
    debug           => $openstack_verbose,
    verbose         => $openstack_debug,
    rabbit_hosts    => $openstack_rabbit_servers,
    rabbit_use_ssl     => $rabbit_use_ssl,
    kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
    kombu_ssl_certfile => $kombu_ssl_certfile,
    kombu_ssl_keyfile  => $kombu_ssl_keyfile,
    rpc_backend        => 'rabbit'
  } ->
  class { '::ceilometer::db':
    database_connection => $mongo_connection
  }->
  class { '::ceilometer::agent::auth':
    auth_url         => $auth_url,
    auth_password    => $auth_password,
    auth_tenant_name => $auth_tenant_name,
    auth_user        => $auth_username,
  }
  ->
  class { '::ceilometer::collector': } ->
  file { '/etc/ceilometer/pipeline.yaml':
    ensure => file,
    content => template('contrail/pipeline.yaml.erb'),
  } ->
  class { '::ceilometer::agent::central':
    coordination_url => $coordination_url
  }
  case $package_sku {
    /13\.0/: {
      class { '::ceilometer::api':
        enabled           => true,
        keystone_auth_uri => $auth_url,
        keystone_password => $ceilometer_password,
      }
    }

    default: {
      class { '::ceilometer::api':
        enabled           => true,
        keystone_host     => $controller_mgmt_address,
        keystone_password => $ceilometer_password,
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
