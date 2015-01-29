class openstack::common::keystone {
  $internal_vip = $::contrail::params::internal_vip

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
    rabbit_port           => '5673',
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
    rabbit_port           => '5672',
  }


}
}
