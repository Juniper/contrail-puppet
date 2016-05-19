# The puppet module to set up a Contrail Config server
class contrail::profile::openstack::provision (
  $neutron_password  = $::contrail::params::os_neutron_password,
  $nova_password     = $::contrail::params::os_nova_password,
  $glance_password   = $::contrail::params::os_glance_password,
  $cinder_password   = $::contrail::params::os_cinder_password,
  $heat_password     = $::contrail::params::os_heat_password,
  $region_name       = $::contrail::params::os_region,
  $controller_mgmt_address   = $::contrail::params::os_controller_mgmt_address,
  $controller_api_address    = $::contrail::params::os_controller_api_address,
  $keystone_admin_email      = $::contrail::params::os_keystone_admin_email,
  $keystone_admin_password   = $::contrail::params::keystone_admin_password,
) {
  $internal_vip = $::contrail::params::internal_vip
  $contrail_internal_vip = $::contrail::params::contrail_internal_vip

  if ($contrail_internal_vip != "" and $contrail_internal_vip != undef) {
    $contrail_controller_address_api = $contrail_internal_vip
    $contrail_controller_address_management = $contrail_internal_vip
  } elsif ($internal_vip != "" and $internal_vip != undef) {
    $contrail_controller_address_api = $controller_api_address
    $contrail_controller_address_management = $controller_mgmt_address
  } else {
    $contrail_controller_address_api = $::contrail::params::config_ip_list[0]
    $contrail_controller_address_management = $::contrail::params::config_ip_list[0]
  }

  $controller_address_management = $controller_mgmt_address
  $address_api = $controller_api_address
  $storage_address_management = $::contrail::params::os_glance_mgmt_address
  $storage_address_api = $::contrail::params::os_glance_api_address

  notify {"keysstone: ${keystone_admin_email} and ${keystone_admin_password}":;}

  class { '::keystone::roles::admin':
    email        => $keystone_admin_email,
    password     => $keystone_admin_password,
    #configure_user => false,
    #configure_user_role => false,
    admin_tenant => 'admin',
    #admin_user_domain   => 'default', # domain for user
    #admin_project_domain => 'default', # domain for project
  } ->
  class { 'keystone::endpoint':
    public_url   => "http://${address_api}:5000",
    admin_url    => "http://${controller_address_management}:35357",
    internal_url => "http://${controller_address_management}:5000",
    region           => $region_name,
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
  }
  class { '::heat::keystone::auth_cfn':
    password         => $heat_password,
    public_address   => $contrail_controller_address_api,
    admin_address    => $contrail_controller_address_management,
    internal_address => $contrail_controller_address_management,
    region           => $region_name,
  }
}
