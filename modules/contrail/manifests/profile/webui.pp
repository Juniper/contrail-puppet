# == Class: contrail::profile::webui
# The puppet module to set up a Contrail WebUI server
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
class contrail::profile::webui (
    $enable_module = $::contrail::params::enable_webui,
    $is_there_roles_to_delete = $::contrail::params::is_there_roles_to_delete,
    $host_roles = $::contrail::params::host_roles
) {

    if ($enable_module and 'webui' in $host_roles and $is_there_roles_to_delete == false) {
        contain ::contrail::webui
    } elsif ((!('webui' in $host_roles)) and ($contrail_roles['webui'] == true)) {
        notify { 'uninstalling webui':; }
        contain ::contrail::uninstall_webui
        Notify['uninstalling webui']->Class['::contrail::uninstall_webui']
    }
}
