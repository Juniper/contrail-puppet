# == Class: contrail::profile::openstack::heat
# The puppet module to set up openstack::heat for contrail
#
#
class contrail::profile::openstack::heat (
  $openstack_verbose = $::contrail::params::openstack_verbose,
  $openstack_debug = $::contrail::params::openstack_debug,
) {
  $heat_auth_encryption_key = hiera(openstack::heat::encryption_key)
  $controller_management_address = hiera(openstack::controller::address::management)
  $openstack_rabbit_servers = $::contrail::params::openstack_rabbit_ip_list
  $internal_vip = $::contrail::params::internal_vip
  $address_api = hiera(openstack::controller::address::api)
  $region_name = hiera(openstack::region)
  $heat_password = hiera(openstack::heat::password)
  $service_password = hiera(openstack::mysql::service_password)

  $database_credentials = join([$service_password, "@", $host_control_ip],'')
  $keystone_db_conn = join(["mysql://nova:",$database_credentials,"/nova"],'')
  $sync_db = $::contrail::params::sync_db
  $rabbitmq_user = hiera(openstack::rabbitmq::user)
  $rabbitmq_password = hiera(openstack::rabbitmq::password)
  $allowed_hosts     = hiera(openstack::mysql::allowed_hosts)

    if ($internal_vip != '' and $internal_vip != undef) {
      $heat_api_bind_host = '0.0.0.0'
      $heat_api_bind_port = '8005'
      $heat_api_cfn_bind_host = '0.0.0.0'
      $heat_api_cfn_bind_port = '8001'
    } else {
      $heat_api_bind_host = $address_api
      $heat_api_bind_port = '8004'
      $heat_api_cfn_bind_host = $address_api
      $heat_api_cfn_bind_port = '8000'
    }

  class {'::heat::db::mysql':
    password => $service_password,
    allowed_hosts => $allowed_hosts,
  }

    class { '::heat::keystone::auth':
      password         => $heat_password,
      public_address   => $address_api,
      admin_address    => $controller_management_address,
      internal_address => $controller_management_address,
      region           => $region_name,
    }

    class { '::heat::keystone::auth_cfn':
      password         => $heat_password,
      public_address   => $address_api,
      admin_address    => $controller_management_address,
      internal_address => $controller_management_address,
      region           => $region_name,
    }

    class { '::heat':
      database_connection => $keystone_db_conn,
      rabbit_hosts       => $openstack_rabbit_servers,
      rabbit_userid      => $rabbitmq_user,
      rabbit_password    => $rabbitmq_password,
      verbose            => $openstack_verbose,
      debug              => $openstack_debug,
      keystone_host     => $controller_management_address,
      keystone_password => $heat_password,
    }

    class { '::heat::api':
      bind_host => $heat_api_bind_host,
      bind_port => $heat_api_bind_port,
    }

    #class { '::heat::api_cfn':
      #bind_host => $heat_api_cfn_bind_host,
      #bind_port => $heat_api_cfn_bind_port,
    #}

    class { '::heat::engine':
      auth_encryption_key => $heat_auth_encryption_key
    }

    $contrail_api_server = $::contrail::params::config_ip_to_use

    heat_config {
      'DEFAULT/plugin_dirs': value => '/usr/lib/heat/resources';
      'clients_contrail/user': value => 'admin';
      'clients_contrail/password': value => 'contrail123';
      'clients_contrail/tenent': value => 'admin';
      'clients_contrail/api_server': value => $contrail_api_server;
      'clients_contrail/api_base_url': value => '/';
    }

    notify { "contrail::profile::openstack::heat - heat_api_bind_host = ${heat_api_bind_host}":; }
    notify { "contrail::profile::openstack::heat - heat_api_bind_port = ${heat_api_bind_port}":; }
    notify { "contrail::profile::openstack::heat - sql_connection = ${keystone_db_conn}":; }
    notify { "contrail::profile::openstack::heat - rabbit_hosts = ${openstack_rabbit_servers}":; }
    notify { "contrail::profile::openstack::heat - contrail_api_server = ${contrail_api_server}":; }
    notify { "contrail::profile::openstack::heat - keystone_auth_public_url = ${::heat::keystone::auth::public_url}":; }

}
