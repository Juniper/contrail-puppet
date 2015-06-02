# Common class for ceilometer installation
# Private, and should not be used on its own
class openstack::common::ceilometer {
  $is_controller = $::openstack::profile::base::is_controller

  #$controller_management_address = $::openstack::config::controller_address_management
  $controller_address_management = hiera(openstack::controller::address::management)
  $contrail_rabbit_port = $::contrail::params::contrail_rabbit_port
  $contrail_rabbit_host = $::contrail::params::contrail_rabbit_host
  $database_ip_list = $::contrail::params::database_ip_list
  $internal_vip = $::contrail::params::internal_vip

  #$ceilometer_mongo_password = $::openstack::config::ceilometer_mongo_password
  $ceilometer_mongo_password = hiera(openstack::ceilometer::mongo::password)
  $ceilometer_password = hiera(openstack::ceilometer::password)
  $ceilometer_meteringsecret = hiera(openstack::ceilometer::meteringsecret)

  $db_string = join([ "mongodb://ceilometer:", $ceilometer_mongo_password, "@", join($database_ip_list,':27017,') ,":27017/ceilometer?replicaSet=rs-ceilometer" ],'')

  $mongo_connection = $db_string

  class { '::ceilometer':
    metering_secret => $ceilometer_meteringsecret,
    #debug           => $::openstack::config::debug,
    #verbose         => $::openstack::config::verbose,
    rabbit_host    => $contrail_rabbit_host,
    #rabbit_userid   => $::openstack::config::rabbitmq_user,
    #rabbit_password => $::openstack::config::rabbitmq_password,
    rabbit_port           => $contrail_rabbit_port,
    auth_strategy   => 'keystone',
  }

  class { '::ceilometer::api':
    enabled           => $is_controller,
    keystone_host     => $controller_management_address,
    keystone_password => $ceilometer_password,
  }

  class { '::ceilometer::db':
      database_connection => $mongo_connection,
      mysql_module        => '2.2',
          #sync_db             => "false",
  }

}
