# This class is used to configure software and services required
# to run config module of contrail software suit.
#
# === Parameters:
#
# [*host_control_ip*]
#     IP address of the server.
#     If server has separate interfaces for management and control, this
#     parameter should provide control interface IP address.
#
# [*collector_ip*]
#     Control interface IP address of the server running collector module
#
# [*database_ip_list*]
#     List of control interface IP addresses of all servers running cassandra service.
#
# [*control_ip_list*]
#     List of control interface IP addresses of all servers running contrail control node.
#
# [*openstack_ip*]
#     IP address of openstack controller node.
#
# [*uuid*]
#     uuid number
#
# [*keystone_ip*]
#     Key stone IP address, if keystone service is running on a node other
#     than openstack controller.
#     (optional) - Default "", meaning use internal_vip if defined, else use
#     same address as first openstack controller.
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
# [*use_certs*]
#     Flag to indicate if certificates to be used for authentication.
#     (Optional) - Defaults to false
#
# [*multi_tenancy*]
#     Flag to indicate if multi tenancy is used for openstack.
#     (optional) - Defaults to true.
#
# [*zookeeper_ip_list*]
#     List of control interface IP addresses of all servers running zookeeper services.
#     (optional) - Defaults to database_ip_list
#
# [*quantum_port*]
#     Quantum port number
#     (optional) - Defaults to "9697"
#
# [*quantum_service_protocol*]
#     Quantum Service protocol value (http or https)
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
# [*keystone_service_tenant*]
#     Keystone service tenant name.
#     (optional) - Defaults to "service".
#
# [*keystone_insecure_flag*]
#     Flag for Keystone secure/insecure
#     (Optional) - Defaults to false
#
# [*api_nworkers*]
#     Number of threads in config API service. This value is also used for number
#     of discovery service threads
#     (Optional) - Defaults to 1.
#
# [*haproxy*]
#     If HAproxy is configured and enabled. Even if this is passed as true (enabled), if
#     contrail_internal_vip is defined, haproxy = false is used.
#     (Optional) - Defaults to false.
#
# [*keystone_region_name*]
#     Keystone region name.
#     (optional) - Defaults to "RegionOne".
#
# [*manage_neutron*]
#     Flag to indicate if configuring neutron user/role in keystone is required.
#     (optional) - Defaults to true
#
# [*openstack_manage_amqp*]
#     flag to indicate if amqp service is managed by openstack node or contrail
#     config node. amqp_server_ip is set based on value of this flag. If false,
#     use contrail_internal_vip or config_ip. If true, use internal_vip or
#     openstack_ip. Note : If amqp_server_ip is specifically provided (next param)
#     that value is used regardless of value of manage_amqp flag.
#     (optional) - Defaults to false, meaning contrail config to manage amqp.
#
# [*amqp_server_ip*]
#     If Rabbitmq is running on a different server, specify its IP address here.
#     (optional) - Defaults to "".
#
# [*openstack_mgmt_ip*]
#     Management interface address of openstack node (if management and control are separate
#     interfaces on that node)
#     (optional) - Defaults to "", meaning use openstack_ip.
#
# [*internal_vip*]
#     Virtual mgmt IP address for openstack modules
#     (optional) - Defaults to ""
#
# [*external_vip*]
#     Virtual control/data IP address for openstack modules
#     (optional) - Defaults to ""
#
# [*contrail_internal_vip*]
#     Virtual mgmt IP address for contrail modules
#     (optional) - Defaults to "", in which case value of internal_vip is used.
#
# [*config_ip_list*]
#     List of control interface IPs of all the servers running config role.
#     (optional) - Defaults to single node (list with host_control_ip)
#     This is used to derive following variables used by this module.
#     - amqp_server_ip : set to contrail_internal_vip or internal_vip or
#       ip address of first config node.
#
# [*config_name_list*]
#     List of hostnames of all servers running config role.
#     (optional) - Defaults to list with current node hostname alone.
#
# [*database_ip_port*]
#     Database IP port number
#     (optional) - Defaults to "9160"
#
# [*zk_ip_port*]
#     Zookeeper IP port number
#     (optional) - Defaults to "2181"
#
# [*hc_interval*]
#     contrail HC interval used by contrail components to send heart beat
#     to discovery service.
#     (Optional) - Defaults to 5 seconds.
#
# [*vmware_ip*]
#     VMware IP address (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*vmware_username*]
#     VMware user name (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*vmware_password*]
#     vmware_password (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*vmware_vswitch*]
#     VMware vswitch value (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::config (
)  {
    contrail::lib::report_status { 'config_started': } ->
    Class['::contrail::config::install'] ->
    Class['::contrail::config::config'] ~>
    Class['::contrail::config::service'] ->
    Class['::contrail::provision_contrail'] ->
    contrail::lib::report_status { 'config_completed': }
    contain ::contrail::config::install
    contain ::contrail::config::config
    contain ::contrail::config::service
    contain ::contrail::provision_contrail
}
