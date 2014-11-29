# The profile to set up the neutron server
class openstack::profile::contrail::neutron::server {
#  require ::openstack::profile::contrail::config

  openstack::resources::controller { 'neutron': }
  openstack::resources::database { 'neutron': }
  openstack::resources::firewall { 'Neutron API': port => '9696', }

  include ::openstack::common::contrail::neutron
}
