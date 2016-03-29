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
    contrail::lib::report_status { 'haproxy_started': } ->
    Class['::contrail::haproxy::install'] ->
    Class['::contrail::haproxy::config'] ~>
    Class['::contrail::haproxy::service'] ->
    contrail::lib::report_status { 'haproxy_completed': }
    contain ::contrail::haproxy::install
    contain ::contrail::haproxy::config
    contain ::contrail::haproxy::service
}
