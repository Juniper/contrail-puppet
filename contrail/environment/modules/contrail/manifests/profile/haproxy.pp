# == Class: contrail::profile::haproxy
# The puppet module to set up a haproxy server
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
class contrail::profile::haproxy (
    $enable_module = $::contrail::params::enable_haproxy
) {
    if ($enable_module) {
        contrail::lib::report_status { "haproxy_started": state => "haproxy_started" } ->
        class {'::contrail::haproxy' : } ->
        contrail::lib::report_status { "haproxy_completed": state => "haproxy_completed" }
    }
}
