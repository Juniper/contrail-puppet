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
    $enable_ceilometer = $::contrail::params::enable_ceilometer
) {
    if ($enable_module) {
        contain ::contrail::database
        if ($enable_ceilometer) {
            include ::contrail::profile::mongodb
        }
    }
}
