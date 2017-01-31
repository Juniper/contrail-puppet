class contrail::profile::openstack::keystone(
  $internal_vip       = $::contrail::params::internal_vip,
  $host_control_ip    = $::contrail::params::host_ip,
  $sync_db            = $::contrail::params::os_sync_db,
  $package_sku        = $::contrail::params::package_sku,
  $openstack_verbose  = $::contrail::params::os_verbose,
  $openstack_debug    = $::contrail::params::os_debug,
  $service_password   = $::contrail::params::os_mysql_service_password,
  $allowed_hosts      = $::contrail::params::os_mysql_allowed_hosts,
  $admin_token        = $::contrail::params::os_keystone_admin_token,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
  $rabbit_use_ssl     = $::contrail::params::os_amqp_ssl,
  $kombu_ssl_ca_certs = $::contrail::params::kombu_ssl_ca_certs,
  $kombu_ssl_certfile = $::contrail::params::kombu_ssl_certfile,
  $kombu_ssl_keyfile  = $::contrail::params::kombu_ssl_keyfile,
  $keystone_version   = $::contrail::params::keystone_version,
  $openstack_rabbit_servers        = $::contrail::params::openstack_rabbit_ip_list,
  $keystone_mysql_service_password = $::contrail::params::keystone_mysql_service_password,
  $global_controller_ip_list       = $::contrail::params::global_controller_ip_list
) {

  if ($keystone_mysql_service_password != "") {
    $service_password_to_use = $keystone_mysql_service_password
  } else {
    $service_password_to_use = $service_password
  }

  class {'::keystone::db::mysql':
    password => $service_password,
    allowed_hosts => $allowed_hosts,
  }

  if ($keystone_version == "v3") {
    file { '/etc/keystone/policy.v3cloudsample.json' :
      ensure  => present,
      content => template("${module_name}/policy.v3cloudsample.json"),
    }
  }

  if ($internal_vip != "" and $internal_vip != undef) {
    $mysql_port_url = ":3306/keystone"
    $keystone_public_port = "6000"
    $keystone_admin_port  = "35358"
  } else {
    $mysql_port_url = "/keystone"
    $keystone_public_port = "5000"
    $keystone_admin_port = "35357"
  }

  $database_credentials = join([$service_password_to_use, "@", $keystone_ip_to_use],'')
  $keystone_db_conn = join(["mysql://keystone:",$database_credentials, $mysql_port_url],'')

  $paste_config =  ''

  case $package_sku {
    /13\.0/: {
      class { '::keystone':
        database_connection => $keystone_db_conn,
        admin_token     =>  $admin_token,
        public_port     => $keystone_public_port,
        admin_port      => $keystone_admin_port,
        rabbit_hosts    => $openstack_rabbit_servers,
        verbose         => $openstack_verbose,
        debug           => $openstack_debug,
        sync_db         => $sync_db,
        database_idle_timeout   => '180',
        database_min_pool_size  => "100",
        database_max_pool_size  => "700",
        database_max_overflow   => "100",
        database_retry_interval => "-1",
        database_max_retries    => "-1",
        rabbit_use_ssl     => $rabbit_use_ssl,
        kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
        kombu_ssl_certfile => $kombu_ssl_certfile,
        kombu_ssl_keyfile  => $kombu_ssl_keyfile
      }

      if ($keystone_version == "v3") {
        keystone_config {
          'oslo_policy/policy_file' : value => "policy.v3cloudsample.json";
        }
      }
    }

    default: {
      class { '::keystone':
        database_connection => $keystone_db_conn,
        enable_bootstrap    => false,
        admin_token     => $admin_token,
        paste_config    => $paste_config,
        admin_bind_host => $admin_bind_host,
        public_port     => $keystone_public_port,
        admin_port      => $keystone_admin_port,
        rabbit_hosts    => $openstack_rabbit_servers,
        verbose         => $openstack_verbose,
        debug           => $openstack_debug,
        sync_db         => $sync_db,
        rabbit_use_ssl     => $rabbit_use_ssl,
        kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
        kombu_ssl_certfile => $kombu_ssl_certfile,
        kombu_ssl_keyfile  => $kombu_ssl_keyfile
      }
      keystone_config {
        'database/min_pool_size'     : value => "100";
        'database/max_pool_size'     : value => "700";
        'database/max_overflow'      : value => "100";
        'database/retry_interval'    : value => "5";
        'database/max_retries'       : value => "-1";
        'database/db_max_retries'    : value => "-1";
        'database/db_retry_interval' : value => "1";
        'database/connection_debug'  : value => "10";
        'database/pool_timeout'      : value => "120";
      }
    }
  }

  if (size($::contrail::params::global_controller_ip_list) > 0) {
    keystone_config {
        'cors/allowed_origin'   : value => "*";
    }
  }
}
