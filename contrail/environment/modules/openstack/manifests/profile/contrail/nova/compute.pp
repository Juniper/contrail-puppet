# The puppet module to set up a Nova Compute node
class openstack::profile::contrail::nova::compute {
    include ::openstack::common::neutron
    include ::openstack::common::contrail

    $controller_management_address = $::openstack::config::controller_address_management

    $internal_vip = $::contrail::params::internal_vip
    if ($internal_vip != "" and $internal_vip != undef) {
      $contrail_controller_mgmt_addr = $controller_management_address

    } else {
      $contrail_controller_mgmt_addr = $::contrail::params::config_ip_list[0]
    }
    $openstack_rabbit_servers = $::contrail::params::openstack_rabbit_servers

    include contrail::compute
    ->
    class { '::nova::network::neutron':
      neutron_admin_password => $::openstack::config::neutron_password,
      neutron_region_name    => $::openstack::config::region,
      neutron_admin_auth_url => "http://${contrail_controller_mgmt_addr}:35357/v2.0",
      neutron_url            => "http://${contrail_controller_mgmt_addr}:9696",
      vif_plugging_is_fatal  => false,
      vif_plugging_timeout   => '0',
    } ->
    nova_config { 'DEFAULT/rabbit_hosts':
        value => $contrail_rabbit_servers,
        notify => Service['nova-compute']
    }

    service {'nova-compute':
        ensure => 'running'
    }
}
