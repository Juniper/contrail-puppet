# This class is used to configure software and services required
# to run compute module (vrouter and agent) of contrail software suit.
#
# === Parameters:
#
# [*host_control_ip*]
#     IP address of the server.
#     If server has separate interfaces for management and control, this
#     parameter should provide control interface IP address.
#
# [*config_ip*]
#     Control interface IP address of the server where config module of
#     contrail cluster is configured. If there are multiple config nodes,
#     specify address of first config node. Actual value used by this module
#     logic would be contrail_internal_vip or internal_vip, if those are 
#     specified for HA setup.
#
# [*openstack_ip*]
#     IP address of server running openstack services. If the server has
#     separate interfaces for management and control, this parameter
#     should provide control interface IP address.
#
# [*control_ip_list*]
#     List of IP addresses running contrail controller module. This is used
#     to derive number of control nodes (needed to be added to config file).
#
# [*compute_ip_list*]
#     List of IP addresses running contrail compute module. This is used
#     to decide is nfs is to be created, this is done on first node only.
#
# [*keystone_ip*]
#     IP address of server running keystone service. Should be specified if
#     keystone is running on a server other than openstack server.
#     (optional) - Defaults to "", meaning use openstack_ip.
#
# [*keystone_auth_protocol*]
#     Keystone authentication protocol.
#     (optional) - Defaults to "http".
#
# [*keystone_auth_port*]
#     Keystone authentication port.
#     (optional) - Defaults to "35357".
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
# [*neutron_service_protocol*]
#     Neutron Service protocol.
#     (optional) - Defaults to "http".
#
# [*keystone_admin_user*]
#     Keystone admin user.
#     (optional) - Defaults to "admin".
#
# [*keystone_admin_password*]
#     Keystone admin password.
#     (optional) - Defaults to "contrail123"
#
# [*keystone_admin_tenant*]
#     Keystone admin tenant name.
#     (optional) - Defaults to "admin".
#
# [*haproxy*]
#     whether haproxy is configured and enabled. If internal_vip or contrail_internal_vip
#     is specified, value of false is used by the logic in this module.
#     (optional) - Defaults to false. 
#
# [*host_non_mgmt_ip*]
#     Specify address of data/control interface, only if there are separate interfaces
#     for management and data/control. If system has single interface for both, leave
#     default value of "".
#     (optional) - Defaults to "".
#
# [*host_non_mgmt_gateway*]
#     Gateway IP address of the data interface of the server. If server has separate
#     interfaces for management and control/data, this parameter should provide gateway
#     ip address of data interface.
#     (optional) - Defaults to "".
#
# [*metadata_secret*]
#     metadata secret value from openstack node.
#     (optional) - Defaults to "". 
#
# [*quantum_port*]
#     Quantum port number
#     (optional) - Defaults to "9697"
#
# [*quantum_service_protocol*]
#     Quantum Service protocol value (http or https)
#     (optional) - Defaults to "http".
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
#     (optional) - Defaults to ""
#
# [*vmware_ip*]
#     VM IP address (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*vmware_username*]
#     VM er name (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*vmware_password*]
#     VM password (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*vswitch*]
#     vswitch value (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*vgw_public_subnet*]
#     Public subnet value for virtual gateway configuration.
#     (optional) - Defaults to ""
#
# [*vgw_public_vn_name*]
#     Public virtual network name value for virtual gateway configuration.
#     (optional) - Defaults to ""
#
# [*vgw_interface*]
#     Interface name for virtual gateway configuration.
#     (optional) - Defaults to ""
#
# [*vgw_gateway_routes*]
#     Gateway routes for virtual gateway configuration.
#     (optional) - Defaults to ""
#
# [*nfs_server*]
#     nfs server address for storage
#     (optional) - Defaults to ""
#
# [*orchestrator*]
#     orchestrator being used for launching VMs.
#     (optional) - Defaults to "openstack"
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::compute (
) {
    include ::contrail::params

    anchor {'contrail::compute::start': } ->
    contrail::lib::report_status { 'compute_started': } ->
    class { '::contrail::compute::install': } ->
    class { '::contrail::compute::config': } ~>
    class { '::contrail::compute::service': } ->
    contrail::lib::report_status { "compute_completed": }
    anchor {'contrail::compute::end': }
}
