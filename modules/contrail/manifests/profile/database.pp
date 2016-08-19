# == Class: contrail::profile::database
# The puppet module to set up a Contrail database server
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
class contrail::profile::database (
    $enable_module = $::contrail::params::enable_database,
    $host_roles = $::contrail::params::host_roles,
    $is_there_roles_to_delete = $::contrail::params::is_there_roles_to_delete,
    $enable_ceilometer = $::contrail::params::enable_ceilometer
) {
    if ($enable_module and "database" in $host_roles and $is_there_roles_to_delete == false) {
        contain ::contrail::database
        if ($enable_ceilometer) {
            contain ::contrail::profile::mongodb
            Class['::contrail::database']->Class['::contrail::profile::mongodb']
        }
    } elsif ((!("database" in $host_roles)) and ($contrail_roles["database"] == true)) {
        contain ::contrail::uninstall_database
        notify { "uninstalling database":; } ->
        Class['::contrail::uninstall_database']
    }
}
