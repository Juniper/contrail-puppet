# The profile to install the Glance API and Registry services
# Note that for this configuration API controls the storage,
# so it is on the storage node instead of the control node
class contrail::profile::openstack::cinder(
  $host_control_ip   = $::contrail::params::host_ip,
  $internal_vip      = $::contrail::params::internal_vip,
  $openstack_verbose = $::contrail::params::os_verbose,
  $openstack_debug   = $::contrail::params::os_debug,
  $allowed_hosts     = $::contrail::params::os_mysql_allowed_hosts,
  $rabbitmq_user     = $::contrail::params::os_rabbitmq_user,
  $rabbitmq_password = $::contrail::params::os_rabbitmq_password,
  $cinder_password   = $::contrail::params::os_cinder_password,
  $service_password  = $::contrail::params::os_mysql_service_password,
  $storage_server    = $::contrail::params::os_glance_api_address,
  $openstack_rabbit_servers   = $::contrail::params::openstack_rabbit_ip_list,
  $keystone_auth_host         = $::contrail::params::os_controller_mgmt_address,
) {
  #$api_network = $::openstack::config::network_api
  #$api_address = ip_for_network($api_network)

  $database_credentials = join([$service_password, "@", $host_control_ip],'')
  $keystone_db_conn = join(["mysql://cinder:",$database_credentials,"/cinder"],'')

  $auth_uri = "http://${keystone_auth_host}:5000/"
  $glance_api_server = "${storage_server}:9292"

  class {'::cinder::db::mysql':
    password      => $service_password,
    allowed_hosts => $allowed_hosts,
  }

  if ($internal_vip != '' and $internal_vip != undef) {
    cinder_config {
      'DEFAULT/osapi_volume_listen_port':  value => '9776';
    }
    class { '::cinder':
      database_connection  => $::openstack::resources::connectors::cinder,
      rabbit_hosts     => $openstack_rabbit_servers,
      rabbit_userid   => $rabbitmq_user,
      rabbit_password => $rabbitmq_password,
      debug           => $openstack_debug,
      verbose         => $openstack_verbose,
      database_idle_timeout => '180',
    }
    class { '::cinder::glance':
      glance_api_servers => [ $glance_api_server ],
    }

    cinder_config {
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
    class { '::cinder::api':
      keystone_password => $cinder_password,
      auth_uri         => $auth_uri,
    }
  } else {
    class { '::cinder':
      database_connection  => $keystone_db_conn,
      rabbit_hosts     => $openstack_rabbit_servers,
      rabbit_userid   => $rabbitmq_user,
      rabbit_password => $rabbitmq_password,
      debug           => $openstack_debug,
      verbose         => $openstack_verbose,
      database_idle_timeout => '180',
    }
    class { '::cinder::glance':
      glance_api_servers => [ $glance_api_server ],
    }
    class { '::cinder::api':
      keystone_password => $cinder_password,
      auth_uri         => $auth_uri,
    }
    class { '::cinder::scheduler':
      scheduler_driver => 'cinder.scheduler.simple.SimpleScheduler',
    }
  }
}
