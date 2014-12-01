class openstack::common::keystone {
  class { '::keystone':
    admin_token     => $::openstack::config::keystone_admin_token,
    sql_connection  => $::openstack::resources::connectors::keystone,
    verbose         => $::openstack::config::verbose,
    debug           => $::openstack::config::debug,
    enabled         => true,
    admin_bind_host => $admin_bind_host,
    mysql_module    => '2.2',
    sync_db         => $sync_db,
    rabbit_port           => '5673',
  }
}
