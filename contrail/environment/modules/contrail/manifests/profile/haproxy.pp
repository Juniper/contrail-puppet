# == Class: contrail::profile::haproxy
# The puppet module to set up a haproxy server
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
class contrail::profile::haproxy (
    $enable_module = $::contrail::params::enable_haproxy,
    $host_roles = $::contrail::params::host_roles
) {
  if ($enable_module and ('config' in $host_roles or 'openstack' in $host_roles)) {
      contain ::contrail::haproxy
  } elsif (((!('config' in $host_roles)) and ($contrail_roles['config'] == true)) or
           ((!('openstack' in $host_roles)) and ($contrail_roles['openstack'] == true))
          ) 
  {
        notify { 'uninstalling haproxy':; }
        contrail::lib::report_status { 'uninstall_haproxy_started': state => 'uninstall_haproxy_started' }
        -> class {'::contrail::uninstall_haproxy' : }
        -> contrail::lib::report_status { 'uninstall_haproxy_completed': state => 'uninstall_haproxy_completed' }

  }

}
