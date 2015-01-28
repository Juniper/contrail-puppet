# Common class for cinder installation
# Private, and should not be used on its own
class openstack::common::cinder {
  $internal_vip = $::contrail::params::internal_vip

  if ($internal_vip != "" and $internal_vip != undef) {
    cinder_config {
      'DEFAULT/osapi_volume_listen_port':  value => '9776';
    }
  }
  class { '::cinder':
    sql_connection  => $::openstack::resources::connectors::cinder,
    rabbit_host     => $::openstack::config::controller_address_management,
    rabbit_userid   => $::openstack::config::rabbitmq_user,
    rabbit_password => $::openstack::config::rabbitmq_password,
    debug           => $::openstack::config::debug,
    verbose         => $::openstack::config::verbose,
    mysql_module    => '2.2',
    rabbit_port           => '5673',
  }

  $storage_server = $::openstack::config::storage_address_api
  $glance_api_server = "${storage_server}:9292"

  class { '::cinder::glance':
    glance_api_servers => [ $glance_api_server ],
  }
}
