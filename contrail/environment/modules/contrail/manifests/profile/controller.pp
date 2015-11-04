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
    $enable_module = $::contrail::params::enable_control,
    $host_roles = $::contrail::params::host_roles
) {

    if ($enable_module and "control" in $host_roles) {
        contain ::contrail::control
        #contrail expects neutron server to run on controls
        include ::contrail::profile::neutron_server
    } elsif ((!("control" in $host_roles)) and ($contrail_roles["control"] == true)) {

        notify { "uninstalling control":; }
        contain ::contrail::uninstall_control

    }

}
