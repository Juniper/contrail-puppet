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
    $enable_module = $::contrail::params::enable_config,
    $is_there_roles_to_delete = $::contrail::params::is_there_roles_to_delete,
    $host_roles = $::contrail::params::host_roles
) {

    if ($enable_module and 'config' in $host_roles and $is_there_roles_to_delete == false) {
        contain ::contrail::config
        #contrail expects neutron server to run on configs
        include ::contrail::profile::neutron_server
    } elsif ((!('config' in $host_roles)) and ($contrail_roles['config'] == true)) {

        notify { 'uninstalling config':; }
        contain ::contrail::uninstall_config

    }
}
