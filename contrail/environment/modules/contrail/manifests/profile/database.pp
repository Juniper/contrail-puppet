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
    $ansible_provision = $::contrail::params::ansible_provision,
) {
    if ((!("database" in $host_roles)) and ($contrail_roles["database"] == true) and ($ansible_provision == false)) {
        contain ::contrail::uninstall_database
        notify { "uninstalling database":; } ->
        Class['::contrail::uninstall_database']
    }
}
