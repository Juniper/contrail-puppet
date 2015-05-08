# == Class: contrail::provision_start
# The puppet module to send provision started status to server manager.
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
class contrail::provision_start(
    $state = undef,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $enable_module = $::contrail::params::enable_provision_started
) inherits ::contrail::params {
    if ($enable_module) {
        contrail::lib::report_status { $state:
            state => $state, 
            contrail_logoutput => $contrail_logoutput }
    }
}



