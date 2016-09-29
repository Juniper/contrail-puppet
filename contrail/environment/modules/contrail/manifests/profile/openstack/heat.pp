# == Class: contrail::profile::openstack::heat
# The puppet module to set up openstack::heat for contrail
#
#
class contrail::profile::openstack::heat (
  $heat_auth_encryption_key = $::openstack::config::heat_encryption_key
) {
    openstack::resources::database { 'heat': }

    $controller_management_address = $::openstack::config::controller_address_management
    $openstack_rabbit_servers = $::contrail::params::openstack_rabbit_servers
    $internal_vip = $::contrail::params::internal_vip
    if ($internal_vip != '' and $internal_vip != undef) {
      $heat_api_bind_host = '0.0.0.0'
      $heat_api_bind_port = '8005'
      $heat_api_cfn_bind_host = '0.0.0.0'
      $heat_api_cfn_bind_port = '8001'
      $database_idle_timeout = "180"
    } else {
      $heat_api_bind_host = $::openstack::config::controller_address_api
      $heat_api_bind_port = '8004'
      $heat_api_cfn_bind_host = $::openstack::config::controller_address_api
      $heat_api_cfn_bind_port = '8000'
      # Default value from heat/manifest/init.pp
      $database_idle_timeout = "3600"
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
      database_idle_timeout => $database_idle_timeout,
      rabbit_hosts       => $openstack_rabbit_servers,
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
      auth_encryption_key => $heat_auth_encryption_key
    }

    $contrail_api_server = $::contrail::params::config_ip_to_use

    heat_config {
      'DEFAULT/plugin_dirs': value => "${::python_dist}/vnc_api/gen/heat/resources,${::python_dist}/contrail_heat/resources";
      'clients_contrail/user': value => 'admin';
      'clients_contrail/password': value => 'contrail123';
      'clients_contrail/tenent': value => 'admin';
      'clients_contrail/api_server': value => $contrail_api_server;
      'clients_contrail/api_base_url': value => '/';
    }
    if ($internal_vip != '' and $internal_vip != undef) {
      heat_config {
        'database/min_pool_size'        :  value => "100";
        'database/max_pool_size'        :  value => "350";
        'database/max_overflow'         :  value => "700";
        'database/retry_interval'       :  value => "5";
        'database/max_retries'          :  value => "-1";
        'database/db_max_retries'       :  value => "3";
        'database/db_retry_interval'    :  value => "1";
        'database/connection_debug'     :  value => "10";
        'database/pool_timeout'         :  value => "120";
        'DEFAULT/rabbit_retry_interval' :  value => "10";
        'DEFAULT/rabbit_retry_backoff'  :  value => "5";
        'DEFAULT/rabbit_max_retries'    :  value => "0";
        #'database/idle_timeout'         :  value => "180";
        #'DEFAULT/rabbit_ha_queues'      :  value => "True";
      }
    }

    notify { "contrail::profile::openstack::heat - heat_api_bind_host = ${heat_api_bind_host}":; }
    notify { "contrail::profile::openstack::heat - heat_api_bind_port = ${heat_api_bind_port}":; }
    notify { "contrail::profile::openstack::heat - sql_connection = ${::openstack::resources::connectors::heat}":; }
    notify { "contrail::profile::openstack::heat - rabbit_hosts = ${openstack_rabbit_servers}":; }
    notify { "contrail::profile::openstack::heat - contrail_api_server = ${contrail_api_server}":; }
    notify { "contrail::profile::openstack::heat - keystone_auth_public_url = ${::heat::keystone::auth::public_url}":; }

}
