# Common class for ceilometer installation
# Private, and should not be used on its own
class openstack::common::ceilometer {
  $is_controller = $::openstack::profile::base::is_controller

  $controller_address_management = hiera(openstack::controller::address::management)
  $controller_address_api = hiera(openstack::controller::address::api)
  $openstack_region = hiera(openstack::region)
  $contrail_rabbit_port = $::contrail::params::contrail_rabbit_port
  $contrail_rabbit_host = $::contrail::params::contrail_rabbit_host
  $database_ip_list = $::contrail::params::database_ip_list
  $internal_vip = $::contrail::params::internal_vip
  $analytics_node_ip = $::contrail::params::collector_ip_to_use

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
    keystone_host     => $controller_address_management,
    keystone_password => $ceilometer_password,
  }


  class { '::ceilometer::db':
      database_connection => $mongo_connection,
      mysql_module        => '2.2',
      #sync_db             => "false",
  }

  class { '::ceilometer::keystone::auth':
      password         => $ceilometer_password,
      public_address   => $controller_address_api,
      admin_address    => $controller_address_management,
      internal_address => $controller_address_management,
      region           => $openstack_region,
  }


  file { '/etc/ceilometer/pipeline.yaml':
    ensure => file,
    content => template('ceilometer/pipeline.yaml.erb'),
  }

  notify { "openstack::common::ceilometer - ceilometer_password = $ceilometer_password":; }
  notify { "openstack::common::ceilometer - public_address = $controller_address_api":; }
  notify { "openstack::common::ceilometer - admin_address = $controller_address_management":; }
  notify { "openstack::common::ceilometer - region = $openstack_region":; }
  notify { "openstack::common::ceilometer - keystone_auth_public_address = $::ceilometer::keystone::auth::public_address":; }
  notify { "openstack::common::ceilometer - keystone_auth_admin_address = $::ceilometer::keystone::auth::admin_address":; }

}
