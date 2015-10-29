# == Class: contrail::haproxy
#
# This class is used to configure haproxy service on config nodes.
#
# === Parameters:
#
# [*config_ip_list*]
#     List of control interface IP addresses of all the servers running config role.
#
# [*config_name_list*]
#     List of host names of all the servers running config role.
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
# The puppet module to set up a haproxy server
class contrail::haproxy () {
    include ::contrail::params

    anchor { 'contrail::haproxy::start': } ->
    contrail::lib::report_status { 'haproxy_started': } ->
    class { '::contrail::haproxy::install': } ->
    class { '::contrail::haproxy::config': } ~>
    class { '::contrail::haproxy::service': } ->
    contrail::lib::report_status { 'haproxy_completed': }
    anchor { 'contrail::haproxy::end': }
}

