class openstack::role::contrail::compute {
  include ::openstack::profile::firewall
  include ::contrail::profile::nova::compute
}
