# The profile to set up the neutron server on Config node
class contrail::profile::neutron::server(
$host_roles = $::contrail::params::host_roles
)
{
  if (!("openstack" in $host_roles)) {
    openstack::resources::database { 'neutron': }
  }
  include ::contrail::config::neutron
}
