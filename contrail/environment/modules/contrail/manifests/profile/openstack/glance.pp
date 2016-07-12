# The profile to install the Glance API and Registry services
# Note that for this configuration API controls the storage,
# so it is on the storage node instead of the control node
class contrail::profile::openstack::glance(
  $host_control_ip   = $::contrail::params::host_ip,
  $internal_vip      = $::contrail::params::internal_vip,
  $openstack_verbose = $::contrail::params::os_verbose,
  $openstack_debug   = $::contrail::params::os_debug,
  $sync_db           = $::contrail::params::sync_db,
  $service_password  = $::contrail::params::os_mysql_service_password,
  $glance_password   = $::contrail::params::os_glance_password,
  $allowed_hosts     = $::contrail::params::os_mysql_allowed_hosts,
  $rabbitmq_user     = $::contrail::params::os_rabbitmq_user,
  $rabbitmq_password = $::contrail::params::os_rabbitmq_password,
  $contrail_internal_vip      = $::contrail::params::contrail_internal_vip,
  $openstack_rabbit_servers   = $::contrail::params::openstack_rabbit_ip_list,
  $storage_management_address = $::contrail::params::os_glance_mgmt_address,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
  $keystone_region_name = $::contrail::params::keystone_region_name,
) {

  $database_credentials = join([$service_password, "@", $host_control_ip],'')
  $auth_uri = "http://${keystone_ip_to_use}:5000/"
  class {'::glance::db::mysql':
    password => $service_password,
    allowed_hosts => $allowed_hosts,
  }

  if ($internal_vip != '' and $internal_vip != undef) {

    $keystone_db_conn = join(["mysql://glance:",$database_credentials,":33306/glance"],'')
    class { '::glance::api':
      keystone_password => $glance_password,
      keystone_tenant   => 'services',
      keystone_user     => 'glance',
      database_connection  => $keystone_db_conn,
      registry_host     => $storage_address_management,
      verbose           => $openstack_verbose,
      debug             => $openstack_debug,
      enabled           => true,
      database_idle_timeout => '180',
      bind_port         => '9393',
      auth_uri          => $auth_uri,
      auth_host         => $keystone_ip_to_use,
      os_region_name    => $keystone_region_name,
    }
    glance_api_config {
      'database/min_pool_size':            value => "100";
      'database/max_pool_size':            value => "700";
      'database/max_overflow':             value => "1080";
      'database/retry_interval':           value => "5";
      'database/max_retries':              value => "-1";
      'database/db_max_retries':           value => "3";
      'database/db_retry_interval':        value => "1";
      'database/connection_debug':         value => "10";
      'database/pool_timeout':             value => "120";
    }
    glance_registry_config {
      'database/min_pool_size':            value => "100";
      'database/max_pool_size':            value => "700";
      'database/max_overflow':             value => "1080";
      'database/retry_interval':           value => "5";
      'database/max_retries':              value => "-1";
      'database/db_max_retries':           value => "3";
      'database/db_retry_interval':        value => "1";
      'database/connection_debug':         value => "10";
      'database/pool_timeout':             value => "120";
    }
    class { '::glance::registry':
      keystone_password     => $glance_password,
      database_connection   => $keystone_db_conn,
      keystone_tenant       => 'services',
      keystone_user         => 'glance',
      verbose               => $openstack_verbose,
      debug                 => $openstack_debug,
      database_idle_timeout => '180',
      #sync_db               => $sync_db
      sync_db               => true,
      auth_uri              => $auth_uri,
      auth_host             => $keystone_ip_to_use,
    }
  } else {
    $keystone_db_conn = join(["mysql://glance:",$database_credentials,"/glance"],'')
    class { '::glance::api':
      keystone_password => $glance_password,
      keystone_tenant   => 'services',
      keystone_user     => 'glance',
      database_connection    => $keystone_db_conn,
      registry_host     => $storage_address_management,
      verbose           => $openstack_verbose,
      debug             => $openstack_debug,
      enabled           => true,
      auth_uri          => $auth_uri,
      auth_host         => $keystone_ip_to_use,
      os_region_name    => $keystone_region_name,
    }
    class { '::glance::registry':
      keystone_password => $glance_password,
      database_connection  => $keystone_db_conn,
      keystone_tenant   => 'services',
      keystone_user     => 'glance',
      verbose           => $openstack_verbose,
      debug             => $openstack_debug,
      #sync_db           => $sync_db,
      sync_db           => true,
      auth_uri          => $auth_uri,
      auth_host         => $keystone_ip_to_use,
    }
  }

  class { '::glance::backend::file': } ->
  glance_api_config {'DEFAULT/rabbit_hosts':
     value  => $openstack_rabbit_servers,
     notify => Service['glance-api']
  } ->
  class { '::glance::notify::rabbitmq':
    rabbit_userid    => $rabbitmq_user,
    rabbit_password  => $rabbitmq_password,
    rabbit_hosts     => $openstack_rabbit_servers,
  }
}
