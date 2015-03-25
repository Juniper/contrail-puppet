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
    $enable_module = $::contrail::params::enable_haproxy
) {
    if ($enable_module) {
        contain ::contrail::haproxy
    }
}
