# == Class: contrail::ceilometer::agent::auth
# The puppet module to set up contrail::profile::openstack::ceilometer agent authentication parameters
#
#
class contrail::ceilometer::agent::auth {

  # Using hiera function as inheriting contrail::config failed
  $controller_address_management = hiera(openstack::controller::address::management)
  $ceilometer_password = hiera(openstack::ceilometer::password)

  $auth_url = "http://${controller_address_management}:5000/v2.0"
  $auth_password = $ceilometer_password
  $auth_tenant_name = "service"
  $auth_username = "ceilometer"

  class { '::ceilometer::agent::auth':
    auth_url      => $auth_url,
    auth_password => $auth_password,
    auth_tenant_name => $auth_tenant_name,
    auth_user => $auth_username,
  }
  notify { "contrail::ceilometer::agent::auth - auth_url = $::ceilometer::agent::auth::auth_url":; }
}
