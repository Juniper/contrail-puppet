# == Class: contrail::profile::config
# The puppet module to set up a Contrail Config server
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
class contrail::profile::config (
    $enable_module = $::contrail::params::enable_config
) {
    if ($enable_module) {
        contain ::contrail::config
        #contrail expects neutron server to run on configs
        contain ::contrail::profile::neutron_server
    }
}
