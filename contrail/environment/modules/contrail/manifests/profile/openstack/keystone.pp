class contrail::profile::openstack::keystone(
  $internal_vip = $::contrail::params::internal_vip,
  $host_control_ip = $::contrail::params::host_ip,
  $sync_db = $::contrail::params::sync_db,
  $openstack_verbose = $::contrail::params::os_verbose,
  $openstack_debug   = $::contrail::params::os_debug,
  $service_password  = $::contrail::params::os_mysql_service_password,
  $allowed_hosts     = $::contrail::params::os_mysql_allowed_hosts,
  $admin_token       = $::contrail::params::os_keystone_admin_token,
  $openstack_rabbit_servers = $::contrail::params::openstack_rabbit_ip_list,
) {
  notify { "SYNC_DB = $sync_db":; }
  notify { "rabbit-servers => $openstack_rabbit_servers":;}

  $database_credentials = join([$service_password, "@", $host_control_ip],'')

  notify {"VALUES => ${admin_token}, ${keystone_db_conn}, ${admin_bind_host}, ${sync_db}, ${openstack_rabbit_servers}":;}

  class {'::keystone::db::mysql':
    password => $service_password,
    allowed_hosts => $allowed_hosts,
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
