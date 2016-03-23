# == Class: contrail::collector
#
# This class is used to configure software and services required
# to run collector or analytics module of contrail software suit.
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
#     contrail cluster is configured. If there are multiple config nodes,
#     address of the first config node is specified here.
#
# [*keystone_ip*]
#     Key stone IP address, if keystone service is running on a node other
#     than openstack controller.
#     (optional) - Default "", meaning use internal_vip if defined, else use
#     same address as first openstack controller.
#
# [*openstack_ip*]
#     IP address of openstack controller node.
#
# [*database_ip_list*]
#     List of control interface IP addresses of all the nodes running
#     Database role (cassandra cluster). If current host is also running
#     database services, address of this server is specified as first entry in the list.
#
# [*database_ip_port*]
#     IP port number on which database (cassandra) service listening.
#     (optional) - Defaults to 9160
#
# [*analytics_data_ttl*]
#     Time for which analytics data is maintained.
#     (optional) - Defaults to 48 hours
#
# [*analytics_config_audit_ttl*]
#     TTL for config audit data in hours.
#     (optional) - Defaults to 2160 hours.
#
# [*analytics_statistics_ttl*]
#     TTL for statistics data in hours.
#     (optional) - Defaults to 168 hours.
#
# [*analytics_flow_ttl*]
#     TTL for flow data in hours.
#     (optional) - Defaults to 2 hours.
#
# [*snmp_scan_frequency*]
#     SNMP full scan frequency (in seconds).
#     (optional) - Defaults to 600 seconds.
#
# [*snmp_fast_scan_frequency*]
#     SNMP fast scan frequency (in seconds).
#     (optional) - Defaults to 60 seconds.
#
# [*topology_scan_frequency*]
#     Topology scan frequency (in seconds).
#     (optional) - Defaults to 60 seconds.
#
# [*zookeeper_ip_list*]
#     List of control interface IP addresses of all servers running zookeeper services.
#     (optional) - Defaults to database_ip_list
#
# [*zk_ip_port*]
#     Zookeeper IP port number
#     (optional) - Defaults to "2181"
#
# [*analytics_syslog_port*]
#     TCP and UDP ports to listen on for receiving syslog messages. -1 to disable.
#     (optional) - Defaults to -1 (disable)
#
# [*internal_vip*]
#     Virtual IP on the control/data interface (internal network) to be used for openstack.
#     (optional) - Defaults to "".
#
# [*contrail_internal_vip*]
#     Virtual IP on the control/data interface (internal network) to be used for contrail.
#     (optional) - Defaults to "".
#     (optional) - Defaults to "http".
#
# [*keystone_auth_protocol*]
#     Keystone authentication protocol.
#     (Optional) - Defaults to "http".
#
# [*keystone_auth_port*]
#     Keystone authentication port.
#     (Optional) - Defaults to 35357
#
# [*keystone_admin_user*]
#     Keystone admin user name.
#     (optional) - Defaults to "admin".
#
# [*keystone_admin_password*]
#     Keystone admin password.
#     (optional) - Defaults to "contrail123".
#
# [*keystone_admin_tenant*]
#     Keystone admin tenant name.
#     (optional) - Defaults to "admin".
#
# [*keystone_insecure_flag*]
#     Flag for Keystone secure/insecure
#     (Optional) - Defaults to false
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::collector ()  {
    contrail::lib::report_status { 'collector_started': } ->
    Class['::contrail::collector::install'] ->
    Class['::contrail::collector::config'] ~>
    Class['::contrail::collector::service'] ->
    contrail::lib::report_status { 'collector_completed': }
    contain ::contrail::collector::install
    contain ::contrail::collector::config
    contain ::contrail::collector::service
}
