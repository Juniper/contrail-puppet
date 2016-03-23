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
    $enable_module = $::contrail::params::enable_compute,
    $enable_ceilometer = $::contrail::params::enable_ceilometer,
    $is_there_roles_to_delete = $::contrail::params::is_there_roles_to_delete,
    $host_roles = $::contrail::params::host_roles
) {
    if ($enable_module and "compute" in $host_roles and $is_there_roles_to_delete == false) {
        contain ::openstack::profile::firewall
        contain ::contrail::profile::nova::compute
        Class['::openstack::profile::firewall']->Class['::contrail::profile::nova::compute']
        if ($enable_ceilometer) {
            contain ::openstack::common::ceilometer
            contain ::contrail::ceilometer::agent::auth
            contain ::ceilometer::agent::compute
            Class['::contrail::profile::nova::compute']->Class['::openstack::common::ceilometer']->Class['::contrail::ceilometer::agent::auth']->Class['::ceilometer::agent::compute']
        }
    } elsif ((!("compute" in $host_roles)) and ($contrail_roles["compute"] == true)) {
        notify { "uninstalling compute":; }
        contain ::contrail::uninstall_compute
        Notify["uninstalling compute"]->Class['::contrail::uninstall_compute']
    }
}

