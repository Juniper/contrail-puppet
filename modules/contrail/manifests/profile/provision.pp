# == Class: contrail::profile::config
# The puppet module to do additional provisioning steps for Contrail Config server
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
class contrail::profile::provision (
    $enable_module = $::contrail::params::enable_config,
    $host_roles = $::contrail::params::host_roles
) {

    if ($enable_module and 'config' in $host_roles) {
        contain ::contrail::provision_contrail
    }
}
