class openstack::common::keystone {
  $internal_vip = $::contrail::params::internal_vip
  $sync_db = $::contrail::params::sync_db
  $openstack_rabbit_servers = $::contrail::params::openstack_rabbit_servers

  notify { "SYNC_DB = $sync_db":; }

  if ($internal_vip != "" and $internal_vip != undef) {

    class { '::keystone':
      admin_token     => $::openstack::config::keystone_admin_token,
      sql_connection  => $::openstack::resources::connectors::keystone,
      verbose         => $::openstack::config::verbose,
      debug           => $::openstack::config::debug,
      enabled         => true,
      admin_bind_host => $admin_bind_host,
      mysql_module    => '2.2',
      sync_db         => $sync_db,
      public_port     => '6000',
      admin_port      => '35358',
      database_idle_timeout => '180',
      rabbit_hosts     => $openstack_rabbit_servers,
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
    class { '::keystone':
      admin_token     => $::openstack::config::keystone_admin_token,
      sql_connection  => $::openstack::resources::connectors::keystone,
      verbose         => $::openstack::config::verbose,
      debug           => $::openstack::config::debug,
      enabled         => true,
      admin_bind_host => $admin_bind_host,
      mysql_module    => '2.2',
      sync_db         => $sync_db,
      rabbit_hosts     => $openstack_rabbit_servers,
    }
    keystone_config {
      'identity/driver':   value => "keystone.identity.backends.sql.Identity";
      'ec2/driver':   value => "keystone.contrib.ec2.backends.sql.Ec2";
      'DEFAULT/onready':   value => "keystone.common.systemd";
    }

  }
}
