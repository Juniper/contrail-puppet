# Common class for cinder installation
# Private, and should not be used on its own
class openstack::common::cinder {
  $internal_vip = $::contrail::params::internal_vip
  $contrail_internal_vip = $::contrail::params::contrail_internal_vip
  $controller_management_address = $::openstack::config::controller_address_management
  $sync_db = $::contrail::params::sync_db

  $contrail_rabbit_host = $::contrail::params::config_ip_to_use
  $contrail_rabbit_port = $::contrail::params::contrail_rabbit_port

  if ($internal_vip != "" and $internal_vip != undef) {
    cinder_config {
      'DEFAULT/osapi_volume_listen_port':  value => '9776';
  }

  class { '::cinder':
    sql_connection  => $::openstack::resources::connectors::cinder,
    rabbit_host     => $contrail_rabbit_host,
    rabbit_userid   => $::openstack::config::rabbitmq_user,
    rabbit_password => $::openstack::config::rabbitmq_password,
    debug           => $::openstack::config::debug,
    verbose         => $::openstack::config::verbose,
    mysql_module    => '2.2',
    rabbit_port     => $contrail_rabbit_port,
  }

  $storage_server = $::openstack::config::storage_address_api
  $glance_api_server = "${storage_server}:9292"

  class { '::cinder::glance':
    glance_api_servers => [ $glance_api_server ],
  }
}
