# The puppet module to set up a Contrail Config server
class openstack::profile::provision {
    require ::openstack::profile::keystone

    $tenants = $::openstack::config::keystone_tenants
    $users   = $::openstack::config::keystone_users
    class { 'keystone::endpoint':
      public_address   => $::openstack::config::controller_address_api,
      admin_address    => $::openstack::config::controller_address_management,
      internal_address => $::openstack::config::controller_address_management,
      region           => $::openstack::config::region,
    } ->
    class { '::keystone::roles::admin':
      email        => $::openstack::config::keystone_admin_email,
      password     => $::openstack::config::keystone_admin_password,
      admin_tenant => 'admin',
    } ->
    class { '::cinder::keystone::auth':
      password         => $::openstack::config::cinder_password,
      public_address   => $::openstack::config::controller_address_api,
      admin_address    => $::openstack::config::controller_address_management,
      internal_address => $::openstack::config::controller_address_management,
      region           => $::openstack::config::region,
    } ->
    class { '::openstack::profile::glance::auth':
    }
    class { '::nova::keystone::auth':
      password         => $::openstack::config::nova_password,
      public_address   => $::openstack::config::controller_address_api,
      admin_address    => $::openstack::config::controller_address_management,
      internal_address => $::openstack::config::controller_address_management,
      region           => $::openstack::config::region,
      cinder           => true,
    }
    class { '::neutron::keystone::auth':
      password         => $::openstack::config::neutron_password,
      public_address   => $::openstack::config::controller_address_api,
      admin_address    => $::openstack::config::controller_address_management,
      internal_address => $::openstack::config::controller_address_management,
      region           => $::openstack::config::region,
    }
#    class { '::ceilometer::agent::auth':
#      auth_url      => "http://${controller_management_address}:5000/v2.0",
#      auth_password => $::openstack::config::ceilometer_password,
#      auth_region   => $::openstack::config::region,
#    }
    create_resources('openstack::resources::tenant', $tenants)
    create_resources('openstack::resources::user', $users)
}
