# == Class: contrail::profile::openstack::heat
# The puppet module to set up openstack::heat for contrail
#
#
class contrail::profile::openstack::heat (
  $host_control_ip   = $::contrail::params::host_ip,
  $allowed_hosts     = $::contrail::params::os_mysql_allowed_hosts,
  $openstack_verbose = $::contrail::params::os_verbose,
  $openstack_debug   = $::contrail::params::os_debug,
  $region_name       = $::contrail::params::os_region,
  $sync_db           = $::contrail::params::sync_db,
  $internal_vip      = $::contrail::params::internal_vip,
  $rabbitmq_user     = $::contrail::params::os_rabbitmq_user,
  $rabbitmq_password = $::contrail::params::os_rabbitmq_password,
  $service_password  = $::contrail::params::os_mysql_service_password,
  $address_api       = $::contrail::params::os_controller_api_address ,
  $heat_password     = $::contrail::params::os_heat_password,
  $encryption_key    = $::contrail::params::os_heat_encryption_key,
  $controller_mgmt_address    = $::contrail::params::os_controller_mgmt_address,
  $openstack_rabbit_servers   = $::contrail::params::openstack_rabbit_hosts,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
) {

  $database_credentials = join([$service_password, "@", $host_control_ip],'')
  $auth_uri = "http://${keystone_ip_to_use}:5000/"
  if ($internal_vip != '' and $internal_vip != undef) {
      $heat_api_bind_host = '0.0.0.0'
      $heat_api_bind_port = '8005'
      $heat_api_cfn_bind_host = '0.0.0.0'
      $heat_api_cfn_bind_port = '8001'
      $keystone_db_conn = join(["mysql://heat:",$database_credentials,":33306/heat"],'')
  } else {
      $heat_api_bind_host = $address_api
      $heat_api_bind_port = '8004'
      $heat_api_cfn_bind_host = $address_api
      $heat_api_cfn_bind_port = '8000'
      $keystone_db_conn = join(["mysql://heat:",$database_credentials,"/heat"],'')
  }

  class {'::heat::db::mysql':
    password => $service_password,
    allowed_hosts => $allowed_hosts,
  }

  class { '::heat':
      database_connection => $keystone_db_conn,
      rabbit_hosts       => $openstack_rabbit_servers,
      rabbit_userid      => $rabbitmq_user,
      rabbit_password    => $rabbitmq_password,
      verbose            => $openstack_verbose,
      debug              => $openstack_debug,
      keystone_host     => $controller_mgmt_address,
      keystone_password => $heat_password,
      auth_uri          => $auth_uri,
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
      auth_encryption_key => $encryption_key
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
  ->
  # We use admin user so need to remove heat_stack_owner from trusts_delegated_roles
  contrail::lib::augeas_conf_rm { "remove_trusts_delegated_roles":
        key => 'trusts_delegated_roles',
        config_file => '/etc/heat/heat.conf',
        lens_to_use => 'properties.lns',
  }

  notify { "contrail::profile::openstack::heat - heat_api_bind_host = ${heat_api_bind_host}":; }
  notify { "contrail::profile::openstack::heat - heat_api_bind_port = ${heat_api_bind_port}":; }
  notify { "contrail::profile::openstack::heat - sql_connection = ${keystone_db_conn}":; }
  notify { "contrail::profile::openstack::heat - rabbit_hosts = ${openstack_rabbit_servers}":; }
  notify { "contrail::profile::openstack::heat - contrail_api_server = ${contrail_api_server}":; }
  notify { "contrail::profile::openstack::heat - keystone_auth_public_url = ${::heat::keystone::auth::public_url}":; }
}
