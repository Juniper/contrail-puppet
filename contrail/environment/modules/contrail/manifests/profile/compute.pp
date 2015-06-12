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
    $enable_ceilometer = $::contrail::params::enable_ceilometer
) {
    if ($enable_module) {
        require ::contrail::common
        require ::openstack::profile::firewall
        require ::contrail::profile::nova::compute

        if ($enable_ceilometer) {
            include ::openstack::common::ceilometer
            include ::contrail::ceilometer::agent::auth
            include ::ceilometer::agent::compute
        }
    }
}

