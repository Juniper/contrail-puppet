# == Class: contrail::profile::keepalived
# The puppet module to set up keepalived for contrail
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
class contrail::profile::keepalived (
    $enable_module = $::contrail::params::enable_keepalived
) {
    if ($enable_module) {
        contrail::lib::report_status { "keepalived_started": state => "keepalived_started" } ->
        class {'::contrail::keepalived' : } ->
        contrail::lib::report_status { "keepalived_completed": state => "keepalived_completed" }
    }
}
