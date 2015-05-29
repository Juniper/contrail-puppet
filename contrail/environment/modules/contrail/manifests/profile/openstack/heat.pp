# == Class: contrail::profile::openstack::heat
# The puppet module to set up openstack::heat for contrail
#
#
class contrail::profile::openstack::heat () {
    openstack::resources::controller { 'heat': }
    openstack::resources::database { 'heat': }
    openstack::resources::firewall { 'Heat API': port     => '8004', }
    openstack::resources::firewall { 'Heat CFN API': port => '8000', }

    $controller_management_address = $::openstack::config::controller_address_management
    $contrail_rabbit_port = $::contrail::params::contrail_rabbit_port
    $contrail_rabbit_host = $::contrail::params::contrail_rabbit_host
    $internal_vip = $::contrail::params::internal_vip
    if ($internal_vip != "" and $internal_vip != undef) {
      $heat_api_bind_host = "0.0.0.0"
      $heat_api_bind_port = "8005"
      $heat_api_cfn_bind_host = "0.0.0.0"
      $heat_api_cfn_bind_port = "8001"
    }
    else {
      $heat_api_bind_host = $::openstack::config::controller_address_api
      $heat_api_bind_port = "8004"
      $heat_api_cfn_bind_host = $::openstack::config::controller_address_api
      $heat_api_cfn_bind_port = "8000"
    }

    class { '::heat::keystone::auth':
      password         => $::openstack::config::heat_password,
      public_address   => $::openstack::config::controller_address_api,
      admin_address    => $::openstack::config::controller_address_management,
      internal_address => $::openstack::config::controller_address_management,
      region           => $::openstack::config::region,
    }

    class { '::heat::keystone::auth_cfn':
      password         => $::openstack::config::heat_password,
      public_address   => $::openstack::config::controller_address_api,
      admin_address    => $::openstack::config::controller_address_management,
      internal_address => $::openstack::config::controller_address_management,
      region           => $::openstack::config::region,
    }

    class { '::heat':
      sql_connection    => $::openstack::resources::connectors::heat,
      rabbit_host       => $contrail_rabbit_host,
      rabbit_port       => $contrail_rabbit_port,
      rabbit_userid     => $::openstack::config::rabbitmq_user,
      rabbit_password   => $::openstack::config::rabbitmq_password,
      debug             => $::openstack::config::debug,
      verbose           => $::openstack::config::verbose,
      keystone_host     => $::openstack::config::controller_address_management,
      keystone_password => $::openstack::config::heat_password,
      mysql_module      => '2.2',
    }

    class { '::heat::api':
      bind_host => $heat_api_bind_host,
      bind_port => $heat_api_bind_port,
    }

    class { '::heat::api_cfn':
      bind_host => $heat_api_cfn_bind_host,
      bind_port => $heat_api_cfn_bind_port,
    }

    class { '::heat::engine':
      auth_encryption_key => $::openstack::config::heat_encryption_key,
    }

    $contrail_api_server = $::contrail::params::config_ip_to_use

    heat_config {
      'DEFAULT/plugin_dirs': value => "/usr/lib/heat/resources";
      'clients_contrail/user': value => "admin";
      'clients_contrail/password': value => "contrail123";
      'clients_contrail/tenent': value => "admin";
      'clients_contrail/api_server': value => $contrail_api_server;
      'clients_contrail/api_base_url': value => "/";
    }

    notify { "contrail::profile::openstack::heat - heat_api_bind_host = $heat_api_bind_host":; }
    notify { "contrail::profile::openstack::heat - heat_api_bind_port = $heat_api_bind_port":; }
    notify { "contrail::profile::openstack::heat - sql_connection = $::openstack::resources::connectors::heat":; }
    notify { "contrail::profile::openstack::heat - rabbit_port = $::heat::rabbit_port":; }
    notify { "contrail::profile::openstack::heat - rabbit_host = $::heat::rabbit_host":; }
    notify { "contrail::profile::openstack::heat - contrail_api_server = $contrail_api_server":; }
    notify { "contrail::profile::openstack::heat - keystone_auth_public_url = $::heat::keystone::auth::public_url":; }

}
