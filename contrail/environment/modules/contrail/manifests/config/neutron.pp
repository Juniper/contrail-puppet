# Common class for neutron installation on Config
# Private, and should not be used on its own
# Sets up configuration common to all neutron nodes.
# Flags install individual services as needed
# This follows the suggest deployment from the neutron Administrator Guide.
class contrail::config::neutron {
  $controller_management_address = $::openstack::config::controller_address_management

  $data_network = $::openstack::config::network_data
  $data_address = ip_for_network($data_network)
  $internal_vip = $::contrail::params::internal_vip


  $contrail_rabbit_servers = $::contrail::params::contrail_rabbit_servers
  $contrail_host_roles = $::contrail::params::host_roles

  # neutron auth depends upon a keystone configuration
  include ::openstack::common::keystone

  # Params from quantum-server-setup.sh are now set here

  # keystone_authtoken params
  $controller = $::contrail::params::keystone_ip_to_use
  $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol
  $keystone_auth_uri = "${keystone_auth_protocol}://${controller}:35357/v2.0/"
  $keystone_identity_uri = "${keystone_auth_protocol}://${controller}:5000"
  $keystone_admin_token = hiera(openstack::keystone::admin_token)


  class { '::neutron':
    rabbit_hosts           => $contrail_rabbit_servers,
    bind_port             => $::contrail::params::quantum_port,
    auth_strategy         => 'keystone',
    core_plugin           => 'neutron_plugin_contrail.plugins.opencontrail.contrail_plugin.NeutronPluginContrailCoreV2',
    allow_overlapping_ips => true,
    rabbit_user           => $::openstack::config::rabbitmq_user,
    rabbit_password       => $::openstack::config::rabbitmq_password,
    debug                 => $::openstack::config::debug,
    verbose               => $::openstack::config::verbose,
    service_plugins       => ['neutron_plugin_contrail.plugins.opencontrail.loadbalancer.plugin.LoadBalancerPlugin'],
  }

  class { '::neutron::server':
    auth_host           => $controller,
    auth_protocol       => $::contrail::params::keystone_auth_protocol,
    auth_tenant         => 'services',
    auth_user           => 'neutron',
    auth_password       => $::openstack::config::neutron_password,
    auth_uri            => $keystone_auth_uri,
    database_connection => $::openstack::resources::connectors::neutron,
    enabled             => $::openstack::profile::base::is_controller,
    mysql_module        => '2.2',
  }

  class { '::neutron::server::notifications':
    nova_url            => "http://${controller_management_address}:8774/v2/",
    nova_admin_auth_url => "http://${controller_management_address}:35357/v2.0/",
    nova_admin_password => $::openstack::config::nova_password,
    nova_region_name    => $::openstack::config::region,
    nova_admin_tenant_id => 'services'
  }

  # Contrail specific neutron config
  $neutron_contrail_params = {
      'keystone_authtoken/identity_uri' => {value => $keystone_identity_uri},
      'quotas/quota_driver' => {value => 'neutron_plugin_contrail.plugins.opencontrail.quota.driver.QuotaDriver'},
      'QUOTAS/quota_network' => {value => '-1'},
      'QUOTAS/quota_subnet' => {value => '-1'},
      'QUOTAS/quota_port' => {value => '-1'},
      'service_providers/service_provider' => {value => 'LOADBALANCER:Opencontrail:neutron_plugin_contrail.plugins.opencontrail.loadbalancer.driver.OpencontrailLoadbalancerDriver:default'},
      'DEFAULT/log_format' => {value => '%(asctime)s.%(msecs)d %(levelname)8s [%(name)s] %(message)s'},
      'DEFAULT/api_extensions_path' => {value => "extensions:${::python_dist}/neutron_plugin_contrail/extensions" }
  }
  create_resources(neutron_config, $neutron_contrail_params, {} )
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
