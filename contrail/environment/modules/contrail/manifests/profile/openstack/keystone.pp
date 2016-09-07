class contrail::profile::openstack::keystone(
  $internal_vip = $::contrail::params::internal_vip,
  $host_control_ip = $::contrail::params::host_ip,
  $sync_db = $::contrail::params::sync_db,
  $package_sku       = $::contrail::params::package_sku,
  $openstack_verbose = $::contrail::params::os_verbose,
  $openstack_debug   = $::contrail::params::os_debug,
  $service_password  = $::contrail::params::os_mysql_service_password,
  $keystone_mysql_service_password = $::contrail::params::keystone_mysql_service_password,
  $allowed_hosts     = $::contrail::params::os_mysql_allowed_hosts,
  $admin_token       = $::contrail::params::os_keystone_admin_token,
  $openstack_rabbit_servers = $::contrail::params::openstack_rabbit_ip_list,
  $keystone_ip_to_use   = $::contrail::params::keystone_ip_to_use,
) {

  if ($keystone_mysql_service_password != "") {
      $service_password_to_use = $keystone_mysql_service_password
  } else {
      $service_password_to_use = $service_password
  }

  $database_credentials = join([$service_password_to_use, "@", $keystone_ip_to_use],'')

  class {'::keystone::db::mysql':
    password => $service_password,
    allowed_hosts => $allowed_hosts,
  }

  $paste_config =  ''
  if ( $package_sku =~ /13\.0/) {
    $default_domain = 'default'
  } else {
    $default_domain = undef
  }

  if ($internal_vip != "" and $internal_vip != undef) {
    $keystone_db_conn = join(["mysql://keystone:",$database_credentials,":3306/keystone"],'')
    class { '::keystone':
      admin_token     =>  $admin_token,
      database_connection => $keystone_db_conn,
      enabled         => true,
      admin_bind_host => $admin_bind_host,
      sync_db         => true,
      public_port     => '6000',
      admin_port      => '35358',
      default_domain  => $default_domain,
      paste_config    => $paste_config,
      database_idle_timeout => '180',
      rabbit_hosts    => $openstack_rabbit_servers,
      verbose         => $openstack_verbose,
      debug           => $openstack_debug,
    }
    keystone_config {
      'database/min_pool_size':   value => "100";
      'database/max_pool_size':   value => "700";
      'database/max_overflow':   value => "100";
      'database/retry_interval':   value => "5";
      'database/max_retries':   value => "-1";
      'database/db_max_retries':   value => "-1";
      'database/db_retry_interval':   value => "1";
      'database/connection_debug':   value => "10";
      'database/pool_timeout':   value => "120";
    }

  } else {
    $keystone_db_conn = join(["mysql://keystone:",$database_credentials,"/keystone"],'')
    class { '::keystone':
      admin_token     =>  $admin_token,
      database_connection => $keystone_db_conn,
      default_domain  => $default_domain,
      paste_config    => $paste_config,
      enabled         => true,
      admin_bind_host => $admin_bind_host,
      sync_db         => true,
      rabbit_hosts    => $openstack_rabbit_servers,
      verbose         => $openstack_verbose,
      debug           => $openstack_debug,
    }
    keystone_config {
      'identity/driver':   value => "keystone.identity.backends.sql.Identity";
      'ec2/driver':   value => "keystone.contrib.ec2.backends.sql.Ec2";
      'DEFAULT/onready':   value => "keystone.common.systemd";
    }
  }

}
