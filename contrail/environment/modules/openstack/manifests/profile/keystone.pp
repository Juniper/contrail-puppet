# The profile to install the Keystone service
class openstack::profile::keystone {

  openstack::resources::controller { 'keystone': }
  openstack::resources::database { 'keystone': }
  openstack::resources::firewall { 'Keystone API': port => '5000', }

  include ::openstack::common::keystone
}
