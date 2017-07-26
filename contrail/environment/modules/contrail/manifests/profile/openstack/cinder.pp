# The profile to install the Glance API and Registry services
# Note that for this configuration API controls the storage,
# so it is on the storage node instead of the control node
class contrail::profile::openstack::cinder(
  $host_control_ip    = $::contrail::params::host_ip,
  $internal_vip       = $::contrail::params::internal_vip,
  $openstack_verbose  = $::contrail::params::os_verbose,
  $openstack_debug    = $::contrail::params::os_debug,
  $allowed_hosts      = $::contrail::params::os_mysql_allowed_hosts,
  $rabbitmq_user      = $::contrail::params::os_rabbitmq_user,
  $rabbitmq_password  = $::contrail::params::os_rabbitmq_password,
  $cinder_password    = $::contrail::params::os_cinder_password,
  $service_password   = $::contrail::params::os_mysql_service_password,
  $storage_server     = $::contrail::params::os_glance_api_address,
  $sync_db            = $::contrail::params::os_sync_db,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
  $package_sku        = $::contrail::params::package_sku,
  $openstack_rabbit_servers   = $::contrail::params::openstack_rabbit_hosts,
  $keystone_auth_host         = $::contrail::params::os_controller_mgmt_address,
  $glance_management_address  = $::contrail::params::os_glance_mgmt_address,
  $keystone_auth_protocol     = $::contrail::params::keystone_auth_protocol,
  $rabbit_use_ssl     = $::contrail::params::os_amqp_ssl,
  $kombu_ssl_ca_certs = $::contrail::params::kombu_ssl_ca_certs,
  $kombu_ssl_certfile = $::contrail::params::kombu_ssl_certfile,
  $kombu_ssl_keyfile  = $::contrail::params::kombu_ssl_keyfile,
  $openstack_ip_to_use = $::contrail::params::openstack_ip_to_use,
) {
  if ($internal_vip != '' and $internal_vip != undef) {
    $mysql_port_url = ":33306/cinder"
    $glance_api_server = "${openstack_ip_to_use}:9292"
    $mysql_ip_address  = $openstack_ip_to_use
    $osapi_volume_port = "9776"
  } else {
    $mysql_port_url = "/cinder"
    $glance_api_server = "${openstack_ip_to_use}:9292"
    $mysql_ip_address  = $host_control_ip
    $osapi_volume_port = "8776"
  }

  $database_credentials = join([$service_password, "@", $mysql_ip_address],'')
  $keystone_db_conn = join(["mysql://cinder:",$database_credentials, $mysql_port_url],'')

  class {'::cinder::db::mysql':
    password      => $service_password,
    allowed_hosts => $allowed_hosts,
  }

  case $package_sku {
    /14\.0/: {
      class { '::cinder':
        database_connection    => $keystone_db_conn,
        rabbit_hosts           => $openstack_rabbit_servers,
        rabbit_userid          => $rabbitmq_user,
        rabbit_password        => $rabbitmq_password,
        debug                  => $openstack_debug,
        verbose                => $openstack_verbose,
        database_idle_timeout  => '180',
        database_min_pool_size => '100',
        database_max_pool_size => '700',
        database_max_retries   => '-1',
        database_retry_interval=> "5",
        database_max_overflow  => "1080",
        rabbit_use_ssl     => $rabbit_use_ssl,
        kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
        kombu_ssl_certfile => $kombu_ssl_certfile,
        kombu_ssl_keyfile  => $kombu_ssl_keyfile
      }
      class { '::cinder::api':
        keystone_password => $cinder_password,
        auth_uri          => "${keystone_auth_protocol}://${keystone_ip_to_use}:5000/",
        sync_db           => $sync_db,
        osapi_volume_listen_port => $osapi_volume_port
      }
    }

    /13\.0/: {
      class { '::cinder':
        database_connection    => $keystone_db_conn,
        rabbit_hosts           => $openstack_rabbit_servers,
        rabbit_userid          => $rabbitmq_user,
        rabbit_password        => $rabbitmq_password,
        debug                  => $openstack_debug,
        verbose                => $openstack_verbose,
        database_idle_timeout  => '180',
        database_min_pool_size => '100',
        database_max_pool_size => '700',
        database_max_retries   => '-1',
        database_retry_interval=> "5",
        database_max_overflow  => "1080",
        rabbit_use_ssl     => $rabbit_use_ssl,
        kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
        kombu_ssl_certfile => $kombu_ssl_certfile,
        kombu_ssl_keyfile  => $kombu_ssl_keyfile
      }

      cinder_config {
        'DEFAULT/osapi_volume_listen_port':  value => $osapi_volume_port;
        'database/db_max_retries':           value => "3";
        'database/db_retry_interval':        value => "1";
        'database/connection_debug':         value => "10";
        'database/pool_timeout':             value => "120";
      }
      class { '::cinder::api':
        keystone_password => $cinder_password,
        auth_uri          => "${keystone_auth_protocol}://${keystone_ip_to_use}:5000/",
        sync_db           => $sync_db
      }
    }

    default: {
      class { '::cinder':
        database_connection    => $keystone_db_conn,
        rabbit_hosts           => $openstack_rabbit_servers,
        rabbit_userid          => $rabbitmq_user,
        rabbit_password        => $rabbitmq_password,
        debug                  => $openstack_debug,
        verbose                => $openstack_verbose,
        database_idle_timeout  => '180',
        database_min_pool_size => '100',
        database_max_pool_size => '700',
        database_max_retries   => '-1',
        database_retry_interval=> "5",
        database_max_overflow  => "1080",
        rabbit_use_ssl     => $rabbit_use_ssl,
        kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
        kombu_ssl_certfile => $kombu_ssl_certfile,
        kombu_ssl_keyfile  => $kombu_ssl_keyfile
      }

      cinder_config {
        'DEFAULT/osapi_volume_listen_port':  value => $osapi_volume_port;
        'database/db_max_retries':           value => "3";
        'database/db_retry_interval':        value => "1";
        'database/connection_debug':         value => "10";
        'database/pool_timeout':             value => "120";
      }
      cinder_config {
        'oslo_messaging_rabbit/heartbeat_timeout_threshold' :  value => '0';
      }
      class { '::cinder::api':
        keystone_password => $cinder_password,
        auth_uri          => "${keystone_auth_protocol}://${keystone_ip_to_use}:5000/",
        sync_db           => $sync_db
      }
    }
  }

  if ($internal_vip != '' and $internal_vip != undef) {
      cinder_config {
        'oslo_messaging_rabbit/rabbit_retry_interval' :  value => '1';
        'oslo_messaging_rabbit/rabbit_retry_backoff' :  value => '2';
        'oslo_messaging_rabbit/rabbit_max_retries' :  value => '0';
      }
  }

  class { '::cinder::scheduler': }

  contrail::lib::augeas_conf_rm { "cinder_rpc_backend":
    key => 'rpc_backend',
    config_file => '/etc/cinder/cinder.conf',
    lens_to_use => 'properties.lns',
    match_value => 'cinder.openstack.common.rpc.impl_kombu',
  }


  class { '::cinder::glance':
    glance_api_servers => [ $glance_api_server ],
  }


}
