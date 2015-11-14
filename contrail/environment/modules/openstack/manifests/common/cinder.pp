# Common class for cinder installation
# Private, and should not be used on its own
class openstack::common::cinder {
  $internal_vip = $::contrail::params::internal_vip
  $contrail_internal_vip = $::contrail::params::contrail_internal_vip
  $controller_management_address = $::openstack::config::controller_address_management
  $sync_db = $::contrail::params::sync_db

  $openstack_rabbit_servers = $::contrail::params::openstack_rabbit_servers 

  if ($internal_vip != "" and $internal_vip != undef) {
    cinder_config {
      'DEFAULT/osapi_volume_listen_port':  value => '9776';
    }

    class { '::cinder':
      sql_connection  => $::openstack::resources::connectors::cinder,
      rabbit_hosts     => $openstack_rabbit_servers,
      rabbit_userid   => $::openstack::config::rabbitmq_user,
      rabbit_password => $::openstack::config::rabbitmq_password,
      debug           => $::openstack::config::debug,
      verbose         => $::openstack::config::verbose,
      mysql_module    => '2.2',
      database_idle_timeout => '180',
    }

    cinder_config {
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
    class { '::cinder':
      sql_connection  => $::openstack::resources::connectors::cinder,
      rabbit_hosts     => $openstack_rabbit_servers,
      rabbit_userid   => $::openstack::config::rabbitmq_user,
      rabbit_password => $::openstack::config::rabbitmq_password,
      debug           => $::openstack::config::debug,
      verbose         => $::openstack::config::verbose,
      mysql_module    => '2.2',
    }


  }


  $storage_server = $::openstack::config::storage_address_api
  $glance_api_server = "${storage_server}:9292"

  class { '::cinder::glance':
    glance_api_servers => [ $glance_api_server ],
  }
}
