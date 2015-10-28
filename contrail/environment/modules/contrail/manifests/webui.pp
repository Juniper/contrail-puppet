# == Class: contrail::webui
#
# This class is used to configure software and services required
# to run webui module of contrail software suit.
#
# === Parameters:
#
# [*config_ip*]
#     Control Interface IP address of the server where config module of 
#     contrail cluster is configured. If there are multiple config nodes
#     this parameter uses IP address of first config node (index = 0).
#
# [*collector_ip*]
#     IP address of the server where analytics module of
#     contrail cluster is configured. If this host is also running
#     collector role, local host address is preferred here, else
#     one of collector nodes is chosen.
#
# [*openstack_ip*]
#     Control interface IP address of openstack node.
#
# [*database_ip_list*]
#     List of control interface IP addresses of all servers running cassandra
#     database roles.
#
# [*is_storage_master*]
#     Flag to Indicate if this server is also running contrail storage master role.A
#     (optional) - Default is false.
#
# [*keystone_ip*]
#     IP address of keystone node, if keystone is run outside openstack.
#     (optional) - Defaults to "", meaning use openstack_ip.
#
# [*internal_vip*]
#     Virtual IP for openstack nodes in case of HA configuration.
#     (Optional) - Defaults to "", meaning no HA configuration.
#
# [*contrail_internal_vip*]
#     Virtual IP for contrail config nodes in case of HA configuration.
#     (Optional) - Defaults to "", meaning no HA configuration.
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::webui () {
    include ::contrail::params

    anchor {'contrail::webui::start':} ->
    contrail::lib::report_status { 'webui_started': } ->
    class { 'contrail::webui::install' : } ->
    class { 'contrail::webui::config' : } ~>
    class { 'contrail::webui::service' : } ->
    contrail::lib::report_status { 'webui_completed': }
    anchor {'contrail::webui::end':}
}
