# The profile to install an OpenStack specific mysql server
class contrail::profile::openstack::auth_file {
  $admin_password           = $::contrail::params::keystone_admin_password
  $controller_node          = $::contrail::params::os_controller_api_address
  $keystone_admin_token     = $::contrail::params::os_keystone_admin_token
  $admin_user               = 'admin'
  $admin_tenant             = 'admin'
  $region_name              = $::contrail::params::os_region
  $use_no_cache             = true
  $cinder_endpoint_type     = 'publicURL'
  $glance_endpoint_type     = 'publicURL'
  $keystone_endpoint_type   = 'publicURL'
  $nova_endpoint_type       = 'publicURL'
  $neutron_endpoint_type    = 'publicURL'

  file { '/root/openrc':
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => template("${module_name}/openrc.erb")
  }
}
