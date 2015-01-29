# Common class for ceilometer installation
# Private, and should not be used on its own
class openstack::common::ceilometer {
  $is_controller = $::openstack::profile::base::is_controller

  $controller_management_address = $::openstack::config::controller_address_management

  $internal_vip = $::contrail::params::internal_vip
  if ($internal_vip != "" and $internal_vip != undef) {
    $contrail_rabbit_port = "5673"
  } else {
    $contrail_rabbit_port = "5672"
  }

  $mongo_password = $::openstack::config::ceilometer_mongo_password
  $mongo_connection =
    "mongodb://${controller_management_address}:27017/ceilometer"

  class { '::ceilometer':
    metering_secret => $::openstack::config::ceilometer_meteringsecret,
    debug           => $::openstack::config::debug,
    verbose         => $::openstack::config::verbose,
    rabbit_hosts    => [$controller_management_address],
    rabbit_userid   => $::openstack::config::rabbitmq_user,
    rabbit_password => $::openstack::config::rabbitmq_password,
    rabbit_port           => $contrail_rabbit_port,
  }

  class { '::ceilometer::api':
    enabled           => $is_controller,
    keystone_host     => $controller_management_address,
    keystone_password => $::openstack::config::ceilometer_password,
  }

  class { '::ceilometer::db':
    database_connection => $mongo_connection,
    mysql_module        => '2.2',
  }


}

