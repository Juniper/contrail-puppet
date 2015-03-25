# == Class: contrail::profile::compute
# The puppet module to set up a Contrail compute Node
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
class contrail::profile::compute (
    $enable_module = $::contrail::params::enable_compute
) {
    if ($enable_module) {
        require ::contrail::common
        require ::openstack::profile::firewall
        require ::contrail::profile::nova::compute
        # require ::openstack::profile::ceilometer::agent
    }
}

