# == Class: contrail::ceilometer::agent::auth
# The puppet module to set up contrail::profile::openstack::ceilometer agent authentication parameters
#
#
class contrail::ceilometer::agent::auth{

  #$controller_management_address = $::openstack::config::controller_address_management
  $controller_address_management = hiera(openstack::controller::address::management)
  $ceilometer_mongo_password = hiera(openstack::ceilometer::mongo::password)
  $ceilometer_password = hiera(openstack::ceilometer::password)
  $ceilometer_meteringsecret = hiera(openstack::ceilometer::meteringsecret)

  $auth_url = "http://${controller_management_address}:5000/v2.0"
  #$auth_password = $::openstack::config::ceilometer_password
  $auth_password = $ceilometer_password
  $auth_tenant_name = "service"
  $auth_username = "ceilometer"

  class { '::ceilometer::agent::auth':
    auth_url      => $auth_url,
    auth_password => $auth_password,
    auth_tenant_name => $auth_tenant_name,
    auth_user => $auth_username,
  }

}
