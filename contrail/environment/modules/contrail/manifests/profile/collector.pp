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
    $enable_module = $::contrail::params::enable_collector,
    $host_roles = $::contrail::params::host_roles
) {
    if ($enable_module and "collector" in $host_roles) {
        contain ::contrail::collector
    } elsif ((!("collector" in $host_roles)) and ($contrail_roles["analytics"] == true)) {

        notify { "uninstalling collector":; }
        contain ::contrail::uninstall_collector

    }

}
