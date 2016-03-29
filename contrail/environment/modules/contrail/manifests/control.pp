# == Class: contrail::control
#
# This class is used to configure software and services required
# to run controller module of contrail software suit.
#
# === Parameters:
#
# [*host_control_ip*]
#     IP address of the server where contrail collector is being installed.
#     if server has separate interfaces for management and control, this
#     parameter should provide control interface IP address.
#
# [*config_ip*]
#     Control interface IP address of the server where config module of
#     contrail cluster is configured. If there are multiple config nodes
#     , IP address of first config node server is specified here.
#
# [*internal_vip*]
#     Virtual IP on the control/data interface (internal network) to be used for openstack.
#     (optional) - Defaults to "".
#
# [*contrail_internal_vip*]
#     Virtual IP on the control/data interface (internal network) to be used for contrail.
#     (optional) - Defaults to "".
#
# [*use_certs*]
#     Flag to indicate whether to use certificates for authentication.
#     (optional) - Defaults to False.
#
# [*puppet_server*]
#     FQDN of puppet master, in case puppet master is used for certificates
#     (optional) - Defaults to "".
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::control (
) {
    contrail::lib::report_status { 'control_started': } ->
    Class['::contrail::control::install'] ->
    Class['::contrail::control::config'] ~>
    Class['::contrail::control::service'] ->
    contrail::lib::report_status { 'control_completed': }
    contain ::contrail::control::install
    contain ::contrail::control::config
    contain ::contrail::control::service
}
