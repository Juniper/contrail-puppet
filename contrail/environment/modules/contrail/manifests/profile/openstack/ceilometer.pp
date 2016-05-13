# == Class: contrail::profile::openstack::ceilometer
# The puppet module to set up openstack::ceilometer for contrail
#
#
class contrail::profile::openstack::ceilometer () {
  $is_controller = $::openstack::profile::base::is_controller

  $controller_address_management = hiera(openstack::controller::address::management)
  $controller_address_api = hiera(openstack::controller::address::api)
  $openstack_region = hiera(openstack::region)
  $openstack_rabbit_servers = $::contrail::params::openstack_rabbit_servers
  $database_ip_list = $::contrail::params::database_ip_list
  $internal_vip = $::contrail::params::internal_vip
  $analytics_node_ip = $::contrail::params::collector_ip_to_use

  $ceilometer_mongo_password = hiera(openstack::ceilometer::mongo::password)
  $ceilometer_password = hiera(openstack::ceilometer::password)
  $ceilometer_meteringsecret = hiera(openstack::ceilometer::meteringsecret)

  #include ::openstack::profile::ceilometer::api
  #include ::contrail::ceilometer::agent::auth
  # Using hiera function as inheriting contrail::config failed
  $ceilometer_password = hiera(openstack::ceilometer::password)

  $db_string = join([ "mongodb://ceilometer:", $ceilometer_mongo_password, "@", join($database_ip_list,':27017,') ,":27017/ceilometer?replicaSet=rs-ceilometer" ],'')

  $mongo_connection = $db_string

  class { '::ceilometer':
    metering_secret => $ceilometer_meteringsecret,
    #debug           => $::openstack::config::debug,
    #verbose         => $::openstack::config::verbose,
    rabbit_hosts    => $openstack_rabbit_servers,
    auth_strategy   => 'keystone',
  } ->

  class { '::ceilometer::api':
    enabled           => $is_controller,
    keystone_host     => $controller_address_management,
    keystone_password => $ceilometer_password,
  } ->


  class { '::ceilometer::db':
      database_connection => $mongo_connection,
      mysql_module        => '2.2',
      #sync_db             => "false",
  } ->

  class { '::ceilometer::keystone::auth':
      password         => $ceilometer_password,
      public_address   => $controller_address_api,
      admin_address    => $controller_address_management,
      internal_address => $controller_address_management,
      region           => $openstack_region,
  } ->


  file { '/etc/ceilometer/pipeline.yaml':
    ensure => file,
    content => template('ceilometer/pipeline.yaml.erb'),
  } ->

  notify { "openstack::common::ceilometer - ceilometer_password = $ceilometer_password":; } ->
  notify { "openstack::common::ceilometer - public_address = $controller_address_api":; }->
  notify { "openstack::common::ceilometer - admin_address = $controller_address_management":; }->
  notify { "openstack::common::ceilometer - region = $openstack_region":; }->
  notify { "openstack::common::ceilometer - keystone_auth_public_address = $::ceilometer::keystone::auth::public_address":; }->
  notify { "openstack::common::ceilometer - keystone_auth_admin_address = $::ceilometer::keystone::auth::admin_address":; }

  $auth_url = "http://${controller_address_management}:5000/v2.0"
  $auth_password = $ceilometer_password
  $auth_tenant_name = 'service'
  $auth_username = 'ceilometer'

  class { '::ceilometer::agent::central':}
  if $::osfamily != 'Debian' {
    class { '::ceilometer::alarm::notifier':
    }

    class { '::ceilometer::alarm::evaluator':
    }
  }

  class { '::ceilometer::collector': } ->

  class { '::ceilometer::agent::auth':
    auth_url         => $auth_url,
    auth_password    => $auth_password,
    auth_tenant_name => $auth_tenant_name,
    auth_user        => $auth_username,
  } ->
  notify { "contrail::ceilometer::agent::auth - auth_url = ${::ceilometer::agent::auth::auth_url}":; } ->
  notify { 'contrail::profile::openstack::ceilometer - Ceilometer has been enabled and will be installed.':; }
}
