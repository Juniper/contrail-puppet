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
  $package_sku       = $::contrail::params::package_sku,
  $controller_mgmt_address    = $::contrail::params::os_controller_mgmt_address,
  $openstack_rabbit_servers   = $::contrail::params::openstack_rabbit_hosts,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
  $rabbit_use_ssl     = $::contrail::params::os_amqp_ssl,
  $kombu_ssl_ca_certs = $::contrail::params::kombu_ssl_ca_certs,
  $kombu_ssl_certfile = $::contrail::params::kombu_ssl_certfile,
  $kombu_ssl_keyfile  = $::contrail::params::kombu_ssl_keyfile,
) {

  if ($internal_vip != '' and $internal_vip != undef) {
    $heat_api_bind_host = '0.0.0.0'
    $heat_api_bind_port = '8005'
    $heat_api_cfn_bind_host = '0.0.0.0'
    $heat_api_cfn_bind_port = '8001'
    $heat_server_ip = $internal_vip
    $mysql_port_url = ":33306/heat"
    $mysql_ip_address  = $internal_vip
  } else {
    $heat_api_bind_host = '0.0.0.0'
    $heat_api_bind_port = '8004'
    $heat_api_cfn_bind_host = '0.0.0.0'
    $heat_api_cfn_bind_port = '8000'
    $heat_server_ip = $host_control_ip
    $mysql_port_url = "/heat"
    $mysql_ip_address  = $host_control_ip
  }

  $auth_uri = "http://${keystone_ip_to_use}:5000/v2.0"
  $database_credentials = join([$service_password, "@", $mysql_ip_address],'')
  $keystone_db_conn = join(["mysql://heat:",$database_credentials,$mysql_port_url],'')

  class {'::heat::db::mysql':
    password => $service_password,
    allowed_hosts => $allowed_hosts,
  }

  case $package_sku {
    /13\.0/: {
      class { '::heat':
        database_connection => $keystone_db_conn,
        rabbit_hosts       => $openstack_rabbit_servers,
        rabbit_userid      => $rabbitmq_user,
        rabbit_password    => $rabbitmq_password,
        verbose            => $openstack_verbose,
        debug              => $openstack_debug,
        keystone_password => $heat_password,
        auth_uri          => $auth_uri,
        rabbit_use_ssl     => $rabbit_use_ssl,
        kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
        kombu_ssl_certfile => $kombu_ssl_certfile,
        kombu_ssl_keyfile  => $kombu_ssl_keyfile
      }
    }

    default:{
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
        rabbit_use_ssl     => $rabbit_use_ssl,
        kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
        kombu_ssl_certfile => $kombu_ssl_certfile,
        kombu_ssl_keyfile  => $kombu_ssl_keyfile
      }
    }
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
    heat_waitcondition_server_url => "http://${heat_server_ip}:8000/v1/waitcondition",
    auth_encryption_key => $encryption_key
  }

  $contrail_api_server = $::contrail::params::config_ip_to_use

  heat_config {
    'DEFAULT/plugin_dirs': value => "${::python_dist}/vnc_api/gen/heat/resources,${::python_dist}/contrail_heat/resources";
    'clients_contrail/user': value => 'admin';
    'clients_contrail/password': value => $heat_password;
    'clients_contrail/tenant': value => 'admin';
    'clients_contrail/api_server': value => $contrail_api_server;
    'clients_contrail/api_base_url': value => '/';
    'clients_contrail/auth_host_ip': value => $keystone_ip_to_use;
    'clients_contrail/use_ssl': value => 'False';
  }
  ->
  # We use admin user so need to remove heat_stack_owner from trusts_delegated_roles
  contrail::lib::augeas_conf_rm { "remove_trusts_delegated_roles":
    key => 'trusts_delegated_roles',
    config_file => '/etc/heat/heat.conf',
    lens_to_use => 'properties.lns',
  }
}
