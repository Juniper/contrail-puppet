# Common class for Glance installation
# Private, and should not be used on its own
# The purpose is to have basic Glance auth configuration options
# set so that services like Tempest can access credentials
# on the controller
class openstack::common::glance {
  $internal_vip = $::contrail::params::internal_vip

  if ($internal_vip != "" and $internal_vip != undef) {
    class { '::glance::api':
      keystone_password => $::openstack::config::glance_password,
      auth_host         => $::openstack::config::controller_address_management,
      keystone_tenant   => 'services',
      keystone_user     => 'glance',
      sql_connection    => $::openstack::resources::connectors::glance,
      registry_host     => $::openstack::config::storage_address_management,
      verbose           => $::openstack::config::verbose,
      debug             => $::openstack::config::debug,
      enabled           => $::openstack::profile::base::is_storage,
      bind_port     => '9393',
      mysql_module      => '2.2',
    }
    $contrail_rabbit_host = $::openstack::config::controller_address_management
    $contrail_rabbit_port = '5673'

  } else {

    class { '::glance::api':
      keystone_password => $::openstack::config::glance_password,
      auth_host         => $::openstack::config::controller_address_management,
      keystone_tenant   => 'services',
      keystone_user     => 'glance',
      sql_connection    => $::openstack::resources::connectors::glance,
      registry_host     => $::openstack::config::storage_address_management,
      verbose           => $::openstack::config::verbose,
      debug             => $::openstack::config::debug,
      enabled           => $::openstack::profile::base::is_storage,
      mysql_module      => '2.2',
    }
    $contrail_rabbit_host = $::contrail::params::config_ip_list[0]
    $contrail_rabbit_port = '5672'

  }

  # basic service config
  glance_api_config {'DEFAULT/rabbit_host': 
     value => $contrail_rabbit_host,
     notify => Service['glance-api']
  }
  glance_api_config {'DEFAULT/rabbit_port': 
     value => $contrail_rabbit_port,
     notify => Service['glance-api']
  }

}
