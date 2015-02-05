# Common class for neutron installation
# Private, and should not be used on its own
# Sets up configuration common to all neutron nodes.
# Flags install individual services as needed
# This follows the suggest deployment from the neutron Administrator Guide.
class openstack::common::neutron {
  $controller_management_address = $::openstack::config::controller_address_management
  $sync_db = $::contrail::params::sync_db
  $data_network = $::openstack::config::network_data
  $data_address = ip_for_network($data_network)

  # neutron auth depends upon a keystone configuration
  include ::openstack::common::keystone

  $internal_vip = $::contrail::params::internal_vip

  if ($internal_vip != "" and $internal_vip != undef) {
    $contrail_auth_host = $::openstack::config::controller_address_management
  } else {
    $contrail_auth_host = $::contrail::params::config_ip_list[0]
  }

  class { '::neutron':
    rabbit_host           => $controller_management_address,
    core_plugin           => 'neutron.plugins.ml2.plugin.Ml2Plugin',
    allow_overlapping_ips => true,
    rabbit_user           => $::openstack::config::rabbitmq_user,
    rabbit_password       => $::openstack::config::rabbitmq_password,
    debug                 => $::openstack::config::debug,
    verbose               => $::openstack::config::verbose,
    service_plugins       => ['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin',
                              'neutron.services.loadbalancer.plugin.LoadBalancerPlugin',
                              'neutron.services.vpn.plugin.VPNDriverPlugin',
                              'neutron.services.firewall.fwaas_plugin.FirewallPlugin',
                              'neutron.services.metering.metering_plugin.MeteringPlugin'],
  }

  class { '::neutron::server':
    auth_host           => $contrail_auth_host,
    auth_password       => $::openstack::config::neutron_password,
    database_connection => $::openstack::resources::connectors::neutron,
    enabled             => $::openstack::profile::base::is_controller,
    sync_db             => $::openstack::profile::base::is_controller,
    mysql_module        => '2.2',
  }

  class { '::neutron::server::notifications':
    nova_url            => "http://${controller_management_address}:8774/v2/",
    nova_admin_auth_url => "http://${controller_management_address}:35357/v2.0/",
    nova_admin_password => $::openstack::config::nova_password,
    nova_region_name    => $::openstack::config::region,
  }

  if $::osfamily == 'redhat' {
    package { 'iproute':
        ensure => latest,
        before => Class['::neutron']
    }
  }
}
