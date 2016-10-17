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
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
  $package_sku        = $::contrail::params::package_sku,
  $openstack_rabbit_servers   = $::contrail::params::openstack_rabbit_hosts,
  $keystone_auth_host         = $::contrail::params::os_controller_mgmt_address,
  $glance_management_address  = $::contrail::params::os_glance_mgmt_address,
) {

  $database_credentials = join([$service_password, "@", $host_control_ip],'')

  if ($internal_vip != '' and $internal_vip != undef) {
    $mysql_port_url = ":3306/cinder"
    $glance_api_server = "${internal_vip}:9292"
  } else {
    $mysql_port_url = "/cinder"
    $glance_api_server = "${glance_management_address}:9292"
  }

  $keystone_db_conn = join(["mysql://cinder:",$database_credentials, $mysql_port_url],'')

  class {'::cinder::db::mysql':
    password      => $service_password,
    allowed_hosts => $allowed_hosts,
  }

  case $package_sku {
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
        database_max_overflow  => "1080"
      }

      cinder_config {
        'DEFAULT/osapi_volume_listen_port':  value => '9776';
        'database/db_max_retries':           value => "3";
        'database/db_retry_interval':        value => "1";
        'database/connection_debug':         value => "10";
        'database/pool_timeout':             value => "120";
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
        database_max_overflow  => "1080"
      }

      cinder_config {
        'DEFAULT/osapi_volume_listen_port':  value => '9776';
        'database/db_max_retries':           value => "3";
        'database/db_retry_interval':        value => "1";
        'database/connection_debug':         value => "10";
        'database/pool_timeout':             value => "120";
      }
      cinder_config {
        'oslo_messaging_rabbit/heartbeat_timeout_threshold' :  value => '0';
      }
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

  class { '::cinder::api':
    keystone_password => $cinder_password,
    auth_uri          => "http://${keystone_ip_to_use}:5000/"
  }

}
