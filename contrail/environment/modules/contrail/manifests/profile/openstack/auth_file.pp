# The profile to install an OpenStack specific mysql server
class contrail::profile::openstack::auth_file(
  $admin_password           = $::contrail::params::keystone_admin_password,
  $keystone_admin_token     = $::contrail::params::os_keystone_admin_token,
  $internal_vip             = $::contrail::params::internal_vip,
  $admin_user               = 'admin',
  $admin_tenant             = 'admin',
  $region_name              = $::contrail::params::os_region,
  $keystone_version         = $::contrail::params::keystone_version,
  $use_no_cache             = true,
  $cinder_endpoint_type     = 'publicURL',
  $glance_endpoint_type     = 'publicURL',
  $keystone_endpoint_type   = 'publicURL',
  $nova_endpoint_type       = 'publicURL',
  $neutron_endpoint_type    = 'publicURL',
) {
  if ($internal_vip != '' and $internal_vip != undef) {
    $controller_node = $::contrail::params::internal_vip
  } else {
    $controller_node = $::contrail::params::os_controller_api_address
  }

  file { '/root/openrc':
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => template("${module_name}/openrc.erb")
  }
}
