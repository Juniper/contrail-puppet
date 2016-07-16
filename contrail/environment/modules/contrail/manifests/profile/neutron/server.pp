# The profile to set up the neutron server on Config node
class contrail::profile::neutron::server(
  $host_roles        = $::contrail::params::host_roles,
  $service_password  = $::contrail::params::os_mysql_service_password,
  $allowed_hosts     = $::contrail::params::os_mysql_allowed_hosts,
)
{
  contain ::contrail::config::neutron
}
