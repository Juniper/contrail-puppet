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
  $keystone_version          = $::contrail::params::keystone_version,
  $keystone_admin_email      = $::contrail::params::os_keystone_admin_email,
  $keystone_admin_password   = $::contrail::params::keystone_admin_password,
  $contrail_controller_address_api = $::contrail::params::contrail_controller_address_api,
  $contrail_controller_address_management = $::contrail::params::contrail_controller_address_management,
  $controller_address_management = $::contrail::params::controller_address_management,
  $address_api       = $::contrail::params::address_api,
  $config_ip_to_use  = $::contrail::params::config_ip_to_use,
  $package_sku       = $::contrail::params::package_sku,
  $keystone_ip_to_use  = $::contrail::params::keystone_ip_to_use,
  $openstack_ip_to_use = $::contrail::params::openstack_ip_to_use,
  $neutron_ip_to_use   = $::contrail::params::neutron_ip_to_use
) {
  $internal_vip = $::contrail::params::internal_vip
  $contrail_internal_vip = $::contrail::params::contrail_internal_vip

  if ( $package_sku =~ /14\.0/) {
    $tenant_id = ""
  } elsif  ( $package_sku =~ /13\.0/) {
    $tenant_id = ""
  } else {
    $tenant_id = "/%(tenant_id)s"
  }
  $endpoint_version = "v2"

  if ($keystone_version == "v3" ) {
    $config_admin_user = false
  } else {
    $config_admin_user = true
  }

  class { 'keystone::endpoint':
    public_url   => "http://${keystone_ip_to_use}:5000",
    admin_url    => "http://${keystone_ip_to_use}:35357",
    internal_url => "http://${keystone_ip_to_use}:5000",
    region       => $region_name,
  } ->
  class { '::keystone::roles::admin':
    email        => $keystone_admin_email,
    password     => $keystone_admin_password,
    configure_user => $config_admin_user,
    configure_user_role => $config_admin_user,
    admin_tenant => 'admin',
  }

  if ($keystone_version == "v3" ) {
    ensure_resource('keystone_user', "admin::Default", {
      'ensure'   => 'present',
      'enabled'  => true,
      'email'    => $keystone_admin_email,
      'password' => $keystone_admin_password,
    })

    ensure_resource('keystone_user_role', "admin::Default@::Default", {
      'roles' => ['admin'],
    })

  }

  keystone_role { ['_member_', 'cloud-admin', 'KeystoneAdmin', 'netadmin', 'sysadmin', 'KeystoneServiceAdmin', 'Member']:
    ensure => present,
  }

  class { '::cinder::keystone::auth':
    password     => $cinder_password,
    public_url   => "http://${openstack_ip_to_use}:8776/v1/%(tenant_id)s",
    admin_url    => "http://${openstack_ip_to_use}:8776/v1/%(tenant_id)s",
    internal_url => "http://${openstack_ip_to_use}:8776/v1/%(tenant_id)s",
    region       => $region_name,
  } ->
  class  { '::glance::keystone::auth':
    password     => $glance_password,
    public_url   => "http://${openstack_ip_to_use}:9292",
    admin_url    => "http://${openstack_ip_to_use}:9292",
    internal_url => "http://${openstack_ip_to_use}:9292",
    region       => $region_name,
  } ->
  class { '::nova::keystone::auth':
    password         => $nova_password,
    public_url       => "http://${openstack_ip_to_use}:8774/${endpoint_version}${tenant_id}",
    admin_url        => "http://${openstack_ip_to_use}:8774/${endpoint_version}${tenant_id}",
    internal_url     => "http://${openstack_ip_to_use}:8774/${endpoint_version}${tenant_id}",
    #ec2_public_url   => "http://${openstack_ip_to_use}:8773/services/Cloud",
    #ec2_admin_url    => "http://${openstack_ip_to_use}:8773/services/Admin",
    #ec2_internal_url => "http://${openstack_ip_to_use}:8773/services/Cloud",
    public_url_v3    => "http://${openstack_ip_to_use}:8774/v3",
    admin_url_v3     => "http://${openstack_ip_to_use}:8774/v3",
    internal_url_v3  => "http://${openstack_ip_to_use}:8774/v3",
    region           => $region_name,
  } ->
  class { '::neutron::keystone::auth':
    password         => $neutron_password,
    public_url       => "http://$neutron_ip_to_use:9696",
    admin_url        => "http://$neutron_ip_to_use:9696",
    internal_url     => "http://$neutron_ip_to_use:9696",
    region           => $region_name,
  } ->
  class { '::ceilometer::keystone::auth':
    password         => $ceilometer_password,
    public_url       => "http://$openstack_ip_to_use:8777",
    admin_url        => "http://$openstack_ip_to_use:8777",
    internal_url     => "http://$openstack_ip_to_use:8777",
    region           => $region_name,
  } ->
  class { '::heat::keystone::auth':
    password         => $heat_password,
    public_url       => "http://$openstack_ip_to_use:8004/v1/%(tenant_id)s",
    admin_url        => "http://$openstack_ip_to_use:8004/v1/%(tenant_id)s",
    internal_url     => "http://$openstack_ip_to_use:8004/v1/%(tenant_id)s",
    region           => $region_name,
  } ->
  class { '::heat::keystone::auth_cfn':
    password         => $heat_password,
    public_url       => "http://$openstack_ip_to_use:8000/v1",
    admin_url        => "http://$openstack_ip_to_use:8000/v1",
    internal_url     => "http://$openstack_ip_to_use:8000/v1",
    region           => $region_name,
  }
  # if cluster has global-controller referenced provision these endpoints
  $cgc_ip = $::contrail::params::ext_global_controller_ip
  $cgc_port = $::contrail::params::ext_global_controller_port 
  if (($cgc_ip != '') and ($cgc_port != '')) {
    contain ::contrail::profile::global_controller::keystone::auth
    Class['::heat::keystone::auth_cfn'] ->
    Class['::contrail::profile::global_controller::keystone::auth']
  }
}
