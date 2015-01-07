# The puppet module to set up a Nova Compute node
class openstack::profile::contrail::nova::compute {
    include ::openstack::common::neutron
    include ::openstack::common::contrail

    $controller_management_address = $::openstack::config::controller_address_management

    notify { "openstack::profile::contrail::nova::compute - controller_management_address = $controller_management_address":; }
    include contrail::compute
    ->
    class { '::nova::network::neutron':
      neutron_admin_password => $::openstack::config::neutron_password,
      neutron_region_name    => $::openstack::config::region,
      neutron_admin_auth_url => "http://${controller_management_address}:35357/v2.0",
      neutron_url            => "http://${controller_management_address}:9696",
      vif_plugging_is_fatal  => false,
      vif_plugging_timeout   => '0',
    } ->
    nova_config { 'DEFAULT/rabbit_port':
        value => '5673',
        notify => Service['nova-compute']
    }
    service {'nova-compute':
        ensure => 'running'
    }
}
