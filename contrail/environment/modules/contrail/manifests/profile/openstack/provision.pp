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
  $contrail_controller_address_api = $::contrail::params::contrail_controller_address_api,
  $contrail_controller_address_management = $::contrail::params::contrail_controller_address_management,
  $controller_address_management = $::contrail::params::controller_address_management,
  $address_api       = $::contrail::params::address_api,
  $config_ip_to_use  = $::contrail::params::config_ip_to_use,
  $package_sku       = $::contrail::params::package_sku,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
) {
  $internal_vip = $::contrail::params::internal_vip
  $contrail_internal_vip = $::contrail::params::contrail_internal_vip

  if ( $package_sku =~ /13\.0/) {
    $tenant_id = ""
  } else {
    $tenant_id = "/%(tenant_id)s"
  }
    $endpoint_version = "v2"

  class { 'keystone::endpoint':
    public_url   => "http://${keystone_ip_to_use}:5000",
    admin_url    => "http://${keystone_ip_to_use}:35357",
    internal_url => "http://${keystone_ip_to_use}:5000",
    region       => $region_name,
  } ->
  class { '::keystone::roles::admin':
    email        => $keystone_admin_email,
    password     => $keystone_admin_password,
    admin_tenant => 'admin',
  } ->
  class { '::cinder::keystone::auth':
    password     => $cinder_password,
    public_url   => "http://${address_api}:8776/v1/%(tenant_id)s",
    admin_url    => "http://${controller_address_management}:8776/v1/%(tenant_id)s",
    internal_url => "http://${controller_address_management}:8776/v1/%(tenant_id)s",
    region       => $region_name,
  } ->
  class  { '::glance::keystone::auth':
    password     => $glance_password,
    public_url   => "http://${address_api}:9292",
    admin_url    => "http://${controller_address_management}:9292",
    internal_url => "http://${controller_address_management}:9292",
    region       => $region_name,
  } ->
  class { '::nova::keystone::auth':
    password         => $nova_password,
    public_url       => "http://${address_api}:8774/${endpoint_version}${tenant_id}",
    admin_url        => "http://${controller_address_management}:8774/${endpoint_version}${tenant_id}",
    internal_url     => "http://${controller_address_management}:8774/${endpoint_version}${tenant_id}",
    ec2_public_url   => "http://${controller_address_management}:8773/services/Cloud",
    ec2_admin_url    => "http://${controller_address_management}:8773/services/Admin",
    ec2_internal_url => "http://${controller_address_management}:8773/services/Cloud",
    public_url_v3    => "http://${controller_address_management}:8774/v3",
    admin_url_v3     => "http://${controller_address_management}:8774/v3",
    internal_url_v3  => "http://${controller_address_management}:8774/v3",
    region           => $region_name,
  } ->
  class { '::neutron::keystone::auth':
    password         => $neutron_password,
    public_address   => $config_ip_to_use,
    admin_address    => $config_ip_to_use,
    internal_address => $config_ip_to_use,
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
