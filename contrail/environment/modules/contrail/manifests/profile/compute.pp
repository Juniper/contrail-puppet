# == Class: contrail::profile::compute
# The puppet module to set up a Contrail compute Node
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
# [*enable_ceilometer*]
#     Flag to include or exclude ceilometer service as part of openstack module dynamically.
#     (optional) - Defaults to false.
#
class contrail::profile::compute (
  $enable_module     = $::contrail::params::enable_compute,
  $enable_ceilometer = $::contrail::params::enable_ceilometer,
  $host_roles        = $::contrail::params::host_roles,
  $metering_secret   = $::contrail::params::os_metering_secret,
  $openstack_verbose = $::contrail::params::os_verbose,
  $openstack_debug   = $::contrail::params::os_debug,
  $is_there_roles_to_delete   = $::contrail::params::is_there_roles_to_delete,
  $openstack_rabbit_servers   = $::contrail::params::openstack_rabbit_hosts,
) {
    if ($enable_module and "compute" in $host_roles and $is_there_roles_to_delete == false) {
        contain ::contrail::profile::nova::compute
        if ($enable_ceilometer) {
            #contain ::contrail::ceilometer::agent::auth
            if !defined(Class['::ceilometer']) {
              class { '::ceilometer':
                metering_secret => $metering_secret,
                debug           => $openstack_verbose,
                verbose         => $openstack_debug,
                rabbit_hosts    => $openstack_rabbit_servers,
              }
            }
            class { '::ceilometer::agent::compute': }
            ->
            contrail::lib::augeas_conf_rm { "ceilometer_compute_rpc_backend":
                key => 'rpc_backend',
                config_file => '/etc/ceilometer/ceilometer.conf',
                lens_to_use => 'properties.lns'
            }
        }
    } elsif ((!("compute" in $host_roles)) and ($contrail_roles["compute"] == true)) {
        notify { "uninstalling compute":; }
        contain ::contrail::uninstall_compute
        Notify["uninstalling compute"]->Class['::contrail::uninstall_compute']
    }
}

