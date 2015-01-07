# The profile to set up the neutron server
class contrail::profile::openstack::neutron::server inherits ::openstack::role {

  openstack::resources::controller { 'neutron': }
  openstack::resources::database { 'neutron': }
  openstack::resources::firewall { 'Neutron API': port => '9696', }

  include ::openstack::common::contrail::neutron
}
