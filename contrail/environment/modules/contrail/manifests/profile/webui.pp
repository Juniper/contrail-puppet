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
    $enable_module = $::contrail::params::enable_webui
) {
    if ($enable_module) {
        contain ::contrail::webui
    }
}
