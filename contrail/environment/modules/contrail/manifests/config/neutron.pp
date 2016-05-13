# Common class for neutron installation on Config
# Private, and should not be used on its own
# Sets up configuration common to all neutron nodes.
# Flags install individual services as needed
# This follows the suggest deployment from the neutron Administrator Guide.
class contrail::config::neutron (
  $host_control_ip   = $::contrail::params::host_ip,
  $openstack_verbose = $::contrail::params::os_verbose,
  $openstack_debug   = $::contrail::params::os_debug,
  $region_name       = $::contrail::params::os_region,
  $nova_password     = $::contrail::params::os_nova_password,
  $rabbitmq_user     = $::contrail::params::os_rabbitmq_user,
  $rabbitmq_password = $::contrail::params::os_rabbitmq_password,
  $internal_vip      = $::contrail::params::internal_vip,
  $neutron_password  = $::contrail::params::os_neutron_password,
  $service_password  = $::contrail::params::os_mysql_service_password,
  $controller        = $::contrail::params::keystone_ip_to_use,
  $contrail_host_roles     = $::contrail::params::host_roles,
  $contrail_rabbit_servers = $::contrail::params::contrail_rabbit_ip_list,
  $keystone_auth_protocol  = $::contrail::params::keystone_auth_protocol,
  $keystone_admin_token    = $::contrail::params::os_keystone_admin_token,
  $controller_mgmt_address = $::contrail::params::os_controller_mgmt_address,
){

  # Params from quantum-server-setup.sh are now set here

  # Neutron needs to authenticate with keystone but doesn't need keystone installed
  # keystone_authtoken params
  $keystone_auth_uri = "${keystone_auth_protocol}://${controller}:35357/v2.0/"
  $keystone_identity_uri = "${keystone_auth_protocol}://${controller}:5000"

  $database_credentials = join([$service_password, "@", $host_control_ip],'')
  $keystone_db_conn = join(["mysql://neutron:",$database_credentials,"/neutron"],'')


  class { '::neutron':
    rabbit_hosts           => $contrail_rabbit_servers,
    bind_port             => $::contrail::params::quantum_port,
    auth_strategy         => 'keystone',
    core_plugin           => 'neutron_plugin_contrail.plugins.opencontrail.contrail_plugin.NeutronPluginContrailCoreV2',
    allow_overlapping_ips => true,
    rabbit_user           => $rabbitmq_user,
    rabbit_password       => $rabbitmq_password,
    verbose               => $openstack_verbose,
    debug                 => $openstack_debug,
    api_extensions_path   => "extensions:${::python_dist}/neutron_plugin_contrail/extensions",
    service_plugins       => ['neutron_plugin_contrail.plugins.opencontrail.loadbalancer.plugin.LoadBalancerPlugin'],
  }

  class { '::neutron::server':
    auth_password       => $neutron_password,
    #auth_uri            => $keystone_auth_uri,
    #identity_uri        => $keystone_identity_uri,
    database_connection => $keystone_db_conn,
    auth_protocol       => $::contrail::params::keystone_auth_protocol,
    auth_host           => $controller
  }
  class { '::neutron::server::notifications':
    nova_url            => "http://${controller_mgmt_address}:8774/v2/",
    nova_admin_auth_url => "http://${controller_mgmt_address}:35357/v2.0/",
    nova_admin_password => $nova_password,
    nova_region_name    => $region_name,
    nova_admin_tenant_id => 'services'
  }

  # Contrail specific neutron config
  $neutron_contrail_params = {
      #'keystone_authtoken/identity_uri' => {value => $keystone_identity_uri},
      #'keystone_authtoken/auth_protocol' => {value => $::contrail::params::keystone_auth_protocol'},
      #'keystone_authtoken/auth_port' => {value => '35357'},
      #'keystone_authtoken/auth_host' => {value => $controller },
      'quotas/quota_driver' => {value => 'neutron_plugin_contrail.plugins.opencontrail.quota.driver.QuotaDriver'},
      'quotas/quota_network' => {value => '-1'},
      'quotas/quota_subnet' => {value => '-1'},
      'quotas/quota_port' => {value => '-1'},
      'service_providers/service_provider' => {value => 'LOADBALANCER:Opencontrail:neutron_plugin_contrail.plugins.opencontrail.loadbalancer.driver.OpencontrailLoadbalancerDriver:default'},
      'DEFAULT/log_format' => {value => '%(asctime)s.%(msecs)d %(levelname)8s [%(name)s] %(message)s'},
  }
  contrail::lib::augeas_conf_rm { "config_rm_service_provider":
      key => 'service_provider',
      config_file => '/etc/neutron/neutron.conf',
      lens_to_use => 'properties.lns',
  }
  create_resources(neutron_config, $neutron_contrail_params, {} )
  Contrail::Lib::Augeas_conf_rm['config_rm_service_provider'] -> Neutron_config['service_providers/service_provider']
  # Openstack HA specific config
  if (($internal_vip != '')) {
      $neutron_ha_params = {
          'DEFAULT/rabbit_retry_interval' => { value => '1'},
          'DEFAULT/rabbit_retry_backoff' => {value => '2'},
          'DEFAULT/rabbit_max_retries' => { value => '0'},
          'DEFAULT/rpc_cast_timeout' => {value => '30'},
          'DEFAULT/rpc_conn_pool_size' => {value => '40'},
          'DEFAULT/rpc_response_timeout' => { value => '60'},
          'DEFAULT/rpc_thread_pool_size' => {value => '70'}
      }
      create_resources(neutron_config, $neutron_ha_params, {} )
  }
}
