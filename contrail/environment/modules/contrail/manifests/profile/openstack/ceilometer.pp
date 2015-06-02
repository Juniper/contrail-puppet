# == Class: contrail::profile::openstack::ceilometer
# The puppet module to set up openstack::ceilometer for contrail
#
#
class contrail::profile::openstack::ceilometer () {
  include ::openstack::profile::ceilometer::api
  include ::contrail::ceilometer::agent::auth
  notify { "contrail::profile::openstack::ceilometer - Ceilometer has been enabled and will be installed.":; }
}
