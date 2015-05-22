# Common class for Glance installation
# Private, and should not be used on its own
# The purpose is to have basic Glance auth configuration options
# set so that services like Tempest can access credentials
# on the controller
class openstack::common::glance {
  $internal_vip = $::contrail::params::internal_vip
  $contrail_internal_vip = $::contrail::params::contrail_internal_vip

  $contrail_rabbit_host = $::contrail::params::config_ip_to_use
  $contrail_rabbit_port = $::contrail::params::contrail_rabbit_port



  if ($internal_vip != "" and $internal_vip != undef) {
    class { '::glance::api':
      keystone_password => $::openstack::config::glance_password,
      auth_host         => $::openstack::config::controller_address_management,
      keystone_tenant   => 'services',
      keystone_user     => 'glance',
      sql_connection    => $::openstack::resources::connectors::glance,
      registry_host     => $::openstack::config::storage_address_management,
      verbose           => $::openstack::config::verbose,
      debug             => $::openstack::config::debug,
      enabled           => $::openstack::profile::base::is_storage,
      database_idle_timeout => '180',
      bind_port     => '9393',
      mysql_module      => '2.2',
    }

    glance_api_config {
#      'database/idle_timeout':             value => "180";
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
#      'database/idle_timeout':             value => "180";
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

  } else {

    class { '::glance::api':
      keystone_password => $::openstack::config::glance_password,
      auth_host         => $::openstack::config::controller_address_management,
      keystone_tenant   => 'services',
      keystone_user     => 'glance',
      sql_connection    => $::openstack::resources::connectors::glance,
      registry_host     => $::openstack::config::storage_address_management,
      verbose           => $::openstack::config::verbose,
      debug             => $::openstack::config::debug,
      enabled           => $::openstack::profile::base::is_storage,
      mysql_module      => '2.2',
    }

  }


  # basic service config
  glance_api_config {'DEFAULT/rabbit_host': 
     value => $contrail_rabbit_host,
     notify => Service['glance-api']
  }
  ->
  glance_api_config {'DEFAULT/rabbit_port': 
     value => $contrail_rabbit_port,
     notify => Service['glance-api']
  }

}
