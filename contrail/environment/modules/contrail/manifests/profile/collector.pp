# == Class: contrail::profile::collector
# The puppet module to set up a Contrail Collector Node
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
class contrail::profile::collector (
    $enable_module = $::contrail::params::enable_collector
) {
    if ($enable_module) {
        contain ::contrail::collector
    }
}
