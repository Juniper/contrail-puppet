# == Class: contrail::profile::controller
# The puppet module to set up a Contrail Controller server
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
class contrail::profile::controller (
    $enable_module = $::contrail::params::enable_control
) {
    if ($enable_module) {
        contain ::contrail::control
    }
}
