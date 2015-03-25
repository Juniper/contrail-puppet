# == Class: contrail::profile::database
# The puppet module to set up a Contrail database server
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
class contrail::profile::database (
    $enable_module = $::contrail::params::enable_database
) {
    if ($enable_module) {
        contain ::contrail::database
    }
}
