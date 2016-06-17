# The puppet module to set up a Contrail Config server
class contrail::profile::openstack::provision (
  $neutron_password  = $::contrail::params::os_neutron_password,
  $nova_password     = $::contrail::params::os_nova_password,
  $glance_password   = $::contrail::params::os_glance_password,
  $cinder_password   = $::contrail::params::os_cinder_password,
  $heat_password     = $::contrail::params::os_heat_password,
  $region_name       = $::contrail::params::os_region,
  $ceilometer_password       = $::contrail::params::os_ceilometer_password,
  $controller_mgmt_address   = $::contrail::params::os_controller_mgmt_address,
  $controller_api_address    = $::contrail::params::os_controller_api_address,
  $keystone_admin_email      = $::contrail::params::os_keystone_admin_email,
  $keystone_admin_password   = $::contrail::params::keystone_admin_password,
) {
  $internal_vip = $::contrail::params::internal_vip
  $contrail_internal_vip = $::contrail::params::contrail_internal_vip

  if ($contrail_internal_vip != "" and $contrail_internal_vip != undef) {
    $contrail_controller_address_api = $contrail_internal_vip
    $config_address = $contrail_internal_vip
    $contrail_controller_address_management = $contrail_internal_vip
    $controller_address_management = $contrail_internal_vip
    $address_api = $contrail_internal_vip
    $storage_address_management = $contrail_internal_vip
    $storage_address_api = $contrail_internal_vip
  } elsif ($internal_vip != "" and $internal_vip != undef) {
    $config_address = $internal_vip
    $contrail_controller_address_api = $internal_vip
    $contrail_controller_address_management = $internal_vip
    $controller_address_management = $internal_vip
    $address_api = $internal_vip
    $storage_address_management = $internal_vip
    $storage_address_api = $internal_vip
  } else {
    $config_address = $::contrail::params::config_ip_list[0]
    $contrail_controller_address_api =  $::contrail::params::openstack_ip_list[0]
    $contrail_controller_address_management = $::contrail::params::openstack_ip_list[0]
    $controller_address_management = $::contrail::params::openstack_ip_list[0]
    $address_api =  $::contrail::params::openstack_ip_list[0]
    $storage_address_management =  $::contrail::params::openstack_ip_list[0]
    $storage_address_api =  $::contrail::params::openstack_ip_list[0]
  }

  class { 'keystone::endpoint':
    public_url   => "http://${address_api}:5000",
    admin_url    => "http://${controller_address_management}:35357",
    internal_url => "http://${controller_address_management}:5000",
    region       => $region_name,
  } ->
  class { '::keystone::roles::admin':
    email        => $keystone_admin_email,
    password     => $keystone_admin_password,
    admin_tenant => 'admin',
  } ->
  class { '::cinder::keystone::auth':
    password         => $cinder_password,
    public_address   => $address_api,
    admin_address    => $controller_address_management,
    internal_address => $controller_address_management,
    region           => $region_name,
  } ->
  class  { '::glance::keystone::auth':
    password         => $glance_password,
    public_address   => $storage_address_api,
    admin_address    => $storage_address_management,
    internal_address => $storage_address_management,
    region           => $region_name,
  } ->
  class { '::nova::keystone::auth':
    password         => $nova_password,
    public_address   => $address_api,
    admin_address    => $controller_address_management,
    internal_address => $controller_address_management,
    region           => $region_name,
  } ->
  class { '::neutron::keystone::auth':
    password         => $neutron_password,
    public_address   => $config_address,
    admin_address    => $config_address,
    internal_address => $config_address,
    region           => $region_name,
  } ->
  class { '::ceilometer::keystone::auth':
    password         => $ceilometer_password,
    public_address   => $contrail_controller_address_api,
    admin_address    => $contrail_controller_address_management,
    internal_address => $contrail_controller_address_management,
    region           => $region_name,
  } ->
  class { '::heat::keystone::auth':
    password         => $heat_password,
    public_address   => $contrail_controller_address_api,
    admin_address    => $contrail_controller_address_management,
    internal_address => $contrail_controller_address_management,
    region           => $region_name,
  } ->
  class { '::heat::keystone::auth_cfn':
    password         => $heat_password,
    public_address   => $contrail_controller_address_api,
    admin_address    => $contrail_controller_address_management,
    internal_address => $contrail_controller_address_management,
    region           => $region_name,
  }
}
