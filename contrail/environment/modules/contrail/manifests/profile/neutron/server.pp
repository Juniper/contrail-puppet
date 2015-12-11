# The profile to set up the neutron server on Config node
class contrail::profile::neutron::server {

  openstack::resources::database { 'neutron': }

  include ::contrail::config::neutron
}
