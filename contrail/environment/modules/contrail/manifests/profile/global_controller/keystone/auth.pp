# == Class: global_controller::keystone::auth
#
# This class is used to create keystone endpoints required for contrail global controller
#

class contrail::profile::global_controller::keystone::auth (
  $password = $::contrail::params::keystone_admin_password,
  $region   = $::contrail::params::os_region,
  $api_server_ip = $::contrail::params::config_ip_to_use,
  $api_server_port = '8082',
  $opserver_ip = $::contrail::params::collector_ip_to_use,
  $opserver_port = '8081',
  $cgc_ip = $::contrail::params::global_controller_ip,
  $cgc_port = $::contrail::params::global_controller_port,
  $email               = 'gcg@localhost',
  $tenant              = 'services',
  $configure_endpoint  = true,
  $configure_user      = false,
  $configure_user_role = false,
) {

  $api_public_url = "http://${api_server_ip}:${api_server_port}"
  $api_internal_url = $api_public_url
  $opserver_public_url = "http://${opserver_ip}:${opserver_port}"
  $opserver_internal_url = $opserver_public_url
  $cgc_public_url = "http://${cgc_ip}:${cgc_port}"
  $cgc_internal_url = $cgc_public_url

  keystone::resource::service_identity { 'apiserver':
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    service_type        => 'apiserver',
    service_description => 'Contrail Api Server',
    service_name        => 'apiserver',
    region              => $region,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    public_url          => $api_public_url,
    internal_url        => $api_internal_url,
  }

  keystone::resource::service_identity { 'opserver':
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    service_type        => 'opserver',
    service_description => 'Contrail OpServer',
    service_name        => 'opserver',
    region              => $region,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    public_url          => $opserver_public_url,
    internal_url        => $opserver_internal_url,
  }

  keystone::resource::service_identity { 'cgc':
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    service_type        => 'cgc',
    service_description => 'Contrail Global Controller',
    service_name        => 'cgc',
    region              => $region,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    public_url          => $cgc_public_url,
    internal_url        => $cgc_internal_url,
  }
}

