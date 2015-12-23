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
    $host_roles = $::contrail::params::host_roles
) {

    if ($enable_module and 'webui' in $host_roles) {
        contain ::contrail::webui
    } elsif ((!('webui' in $host_roles)) and ($contrail_roles['webui'] == true)) {

        notify { 'uninstalling webui':; }
        contain ::contrail::uninstall_webui

    }

}
