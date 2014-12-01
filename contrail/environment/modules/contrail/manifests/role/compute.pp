class contrail::role::compute {
  include ::openstack::profile::firewall
  include ::contrail::profile::nova::compute
# include ::openstack::profile::ceilometer::agent': }
}
