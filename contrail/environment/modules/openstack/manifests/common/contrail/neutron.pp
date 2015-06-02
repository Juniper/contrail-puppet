# Common class for neutron installation
# Private, and should not be used on its own
# Sets up configuration common to all neutron nodes.
# Flags install individual services as needed
# This follows the suggest deployment from the neutron Administrator Guide.
class openstack::common::contrail::neutron {
  $controller_management_address = $::openstack::config::controller_address_management
  $enable_ceilometer = $::contrail::params::enable_ceilometer
  if ($enable_ceilometer) {
       $notification_driver = 'neutron.openstack.common.notifier.rpc_notifier'
  } else {
       $notification_driver = ''
  }

  $data_network = $::openstack::config::network_data
  $data_address = ip_for_network($data_network)

  $internal_vip = $::contrail::params::internal_vip
  if ($internal_vip != "" and $internal_vip != undef) {
    $contrail_rabbit_port = "5673"
    $contrail_rabbit_host = $controller_management_address
  } else {
    $contrail_rabbit_port = "5672"
    $contrail_rabbit_host = $::contrail::params::config_ip_list[0]
  }


  # neutron auth depends upon a keystone configuration
  include ::openstack::common::keystone

  class { '::neutron':
    rabbit_host           => $contrail_rabbit_host,
    rabbit_port           => $contrail_rabbit_port,
    core_plugin           => 'neutron_plugin_contrail.plugins.opencontrail.contrail_plugin.NeutronPluginContrailCoreV2',
    allow_overlapping_ips => true,
    rabbit_user           => $::openstack::config::rabbitmq_user,
    rabbit_password       => $::openstack::config::rabbitmq_password,
    debug                 => $::openstack::config::debug,
    verbose               => $::openstack::config::verbose,
    service_plugins       => ['neutron_plugin_contrail.plugins.opencontrail.loadbalancer.plugin.LoadBalancerPlugin'],
    notification_driver   => $notification_driver,
  }

  class { '::neutron::server':
    auth_host           => $::openstack::config::controller_address_management,
    auth_password       => $::openstack::config::neutron_password,
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

}
