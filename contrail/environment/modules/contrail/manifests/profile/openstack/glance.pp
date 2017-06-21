# The profile to install the Glance API and Registry services
# Note that for this configuration API controls the storage,
# so it is on the storage node instead of the control node
class contrail::profile::openstack::glance(
  $host_control_ip   = $::contrail::params::host_ip,
  $internal_vip      = $::contrail::params::internal_vip,
  $openstack_verbose = $::contrail::params::os_verbose,
  $openstack_debug   = $::contrail::params::os_debug,
  $sync_db           = $::contrail::params::os_sync_db,
  $service_password  = $::contrail::params::os_mysql_service_password,
  $glance_password   = $::contrail::params::os_glance_password,
  $allowed_hosts     = $::contrail::params::os_mysql_allowed_hosts,
  $rabbitmq_user     = $::contrail::params::os_rabbitmq_user,
  $rabbitmq_password = $::contrail::params::os_rabbitmq_password,
  $package_sku       = $::contrail::params::package_sku,
  $contrail_internal_vip      = $::contrail::params::contrail_internal_vip,
  $openstack_rabbit_servers   = $::contrail::params::openstack_rabbit_hosts,
  $storage_management_address = $::contrail::params::os_glance_mgmt_address,
  $keystone_ip_to_use   = $::contrail::params::keystone_ip_to_use,
  $keystone_region_name = $::contrail::params::keystone_region_name,
  $openstack_ip_to_use  = $::contrail::params::openstack_ip_to_use,
  $rabbit_use_ssl     = $::contrail::params::os_amqp_ssl,
  $kombu_ssl_ca_certs = $::contrail::params::kombu_ssl_ca_certs,
  $kombu_ssl_certfile = $::contrail::params::kombu_ssl_certfile,
  $kombu_ssl_keyfile  = $::contrail::params::kombu_ssl_keyfile,
  $storage_enabled    = $::contrail::params::storage_enabled,
  $keystone_auth_protocol     = $::contrail::params::keystone_auth_protocol
) {

  $auth_uri = "${keystone_auth_protocol}://${keystone_ip_to_use}:5000/"
  $identity_uri = "${keystone_auth_protocol}://${keystone_ip_to_use}:35357/"

  if ($keystone_auth_protocol == "https") {
    $insecure = true
  } else {
    $insecure = false
  }

  class {'::glance::db::mysql':
    password => $service_password,
    allowed_hosts => $allowed_hosts,
  }

  if ($internal_vip != '' and $internal_vip != undef) {
    $mysql_port_url = ":33306/glance"
    $bind_port      = "9393"
    $mysql_ip_address  = $internal_vip
  } else {
    $mysql_port_url = "/glance"
    $bind_port      = "9292"
    $mysql_ip_address  = $host_control_ip
  }

  if ($storage_enabled) {
    $workers = "120"
    $show_image_url = True
    $stores = ['glance.store.rbd.Store','glance.store.filesystem.Store','glance.store.http.Store']
    $default_store = 'rbd'
    $multi_store = True
  } else {
    $workers = $::processorcount
    $show_image_url = False
    $stores = false
    $default_store = undef
    $multi_store = False
  }

  $database_credentials = join([$service_password, "@", $mysql_ip_address],'')
  $keystone_db_conn = join(["mysql://glance:",$database_credentials, $mysql_port_url],'')

  case $package_sku {
    /14\.0/: {
      class { '::glance::api':
        keystone_password => $glance_password,
        keystone_tenant   => 'services',
        keystone_user     => 'glance',
        database_connection  => $keystone_db_conn,
        registry_host     => $openstack_ip_to_use,
        verbose           => $openstack_verbose,
        debug             => $openstack_debug,
        enabled           => true,
        database_idle_timeout => '180',
        bind_port         => $bind_port,
        auth_uri          => $auth_uri,
        os_region_name    => $keystone_region_name,
        database_min_pool_size => "100",
        database_max_pool_size => "700",
        database_max_overflow  => "1080",
        database_retry_interval => "-1",
        database_max_retries   => "-1",
        stores                => $stores,
        default_store         => $default_store,
        multi_store           => $multi_store,
        workers               => $workers,
        show_image_direct_url => $show_image_url
      }
      class { '::glance::registry':
        keystone_password     => $glance_password,
        database_connection   => $keystone_db_conn,
        keystone_tenant       => 'services',
        keystone_user         => 'glance',
        verbose               => $openstack_verbose,
        debug                 => $openstack_debug,
        database_idle_timeout => '180',
        sync_db               => $sync_db,
        database_min_pool_size => "100",
        database_max_pool_size => "700",
        database_max_overflow  => "1080",
        database_retry_interval => "-1",
        database_max_retries   => "-1",
      }
      class { '::glance::backend::file':
        multi_store => $multi_store
       }
    }
    /13\.0/: {
      class { '::glance::api':
        keystone_password => $glance_password,
        keystone_tenant   => 'services',
        keystone_user     => 'glance',
        database_connection  => $keystone_db_conn,
        registry_host     => $openstack_ip_to_use,
        verbose           => $openstack_verbose,
        debug             => $openstack_debug,
        enabled           => true,
        database_idle_timeout => '180',
        bind_port         => $bind_port,
        auth_uri          => $auth_uri,
        os_region_name    => $keystone_region_name,
        database_min_pool_size => "100",
        database_max_pool_size => "700",
        database_max_overflow  => "1080",
        database_retry_interval => "-1",
        database_max_retries   => "-1",
        stores                => $stores,
        default_store         => $default_store,
        multi_store           => $multi_store,
        workers               => $workers,
        show_image_direct_url => $show_image_url
      }
      glance_api_config {
        'database/db_retry_interval':        value => "1";
        'database/connection_debug':         value => "10";
        'database/pool_timeout':             value => "120";
      }
      glance_registry_config {
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
        sync_db               => $sync_db,
        database_min_pool_size => "100",
        database_max_pool_size => "700",
        database_max_overflow  => "1080",
        database_retry_interval => "-1",
        database_max_retries   => "-1",
      }
      class { '::glance::backend::file':
        multi_store => $multi_store
       }
    }

    # Non-mitaka support
    default: {
      class { '::glance::api':
        keystone_password => $glance_password,
        keystone_tenant   => 'services',
        keystone_user     => 'glance',
        database_connection  => $keystone_db_conn,
        registry_host     => $openstack_ip_to_use,
        verbose           => $openstack_verbose,
        debug             => $openstack_debug,
        enabled           => true,
        database_idle_timeout => '180',
        bind_port         => $bind_port,
        auth_uri          => $auth_uri,
        os_region_name    => $keystone_region_name,
      }

      class { '::glance::registry':
        keystone_password     => $glance_password,
        database_connection   => $keystone_db_conn,
        keystone_tenant       => 'services',
        keystone_user         => 'glance',
        verbose               => $openstack_verbose,
        debug                 => $openstack_debug,
        database_idle_timeout => '180',
        sync_db               => $sync_db,
        auth_uri              => $auth_uri,
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
      class { '::glance::backend::file':
      }
    }
  }

  Class [ '::glance::backend::file' ] ->
  class { '::glance::notify::rabbitmq':
    rabbit_userid    => $rabbitmq_user,
    rabbit_password  => $rabbitmq_password,
    rabbit_hosts     => $openstack_rabbit_servers,
    rabbit_use_ssl     => $rabbit_use_ssl,
    kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
    kombu_ssl_certfile => $kombu_ssl_certfile,
    kombu_ssl_keyfile  => $kombu_ssl_keyfile
  }
}
