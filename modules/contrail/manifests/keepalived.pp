# == Class: contrail::keeplived
#
# This class is used to configure software and services required
# to run keepalived services used by contrail software suit.
#
# === Parameters:
#
# [*vip*]
#     Virtual IP address used by the keepalived service.
#     optional - Defaults to "", in which case this class does not do anything!
#
# [*state*]
#     State of VRRP instance (MASTER or SLAVE).
#     (Optional) - Defaults to "MASTER"
#
# [*priority*]
#     Priority used for VRRP.
#     (optional) - Defaults to "101".
#
# [*virtual_router_id*]
#     Virtual router id value.
#     (Optional) - Defaults to "50".
#
# The puppet module to set up keepalived for contrail
class contrail::keepalived(
    $host_control_ip = $::contrail::params::host_ip,
    $config_ip_list = $::contrail::params::config_ip_list,
    $internal_vip = $::contrail::params::internal_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $external_vip = $::contrail::params::external_vip,
    $contrail_external_vip = $::contrail::params::contrail_external_vip,
    $internal_virtual_router_id = $::contrail::params::internal_virtual_router_id,
    $contrail_internal_virtual_router_id = $::contrail::params::contrail_internal_virtual_router_id,
    $external_virtual_router_id = $::contrail::params::external_virtual_router_id,
    $contrail_external_virtual_router_id = $::contrail::params::contrail_external_virtual_router_id,
    $openstack_ip_list = $::contrail::params::openstack_ip_list
)  {

    notify { "Keepalived - host_control_ip = ${host_control_ip}":; } ->
    notify { "Keepalived - config_ip_list = ${config_ip_list}":; } ->
    notify { "Keepalived - internal_vip = ${internal_vip}":; } ->
    notify { "Keepalived - contrail_internal_vip = ${contrail_internal_vip}":; } ->
    notify { "Keepalived - internal_virtual_router_id = ${internal_virtual_router_id}":; } ->
    notify { "Keepalived - contrail_internal_virtual_router_id = ${contrail_internal_virtual_router_id}":; } ->
    notify { "Keepalived - external_virtual_router_id = ${external_virtual_router_id}":; } ->
    notify { "Keepalived - contrail_external_virtual_router_id = ${contrail_external_virtual_router_id}":; } ->
    notify { "Keepalived - openstack_ip_list = ${openstack_ip_list}":; }


    if ($host_control_ip in $openstack_ip_list and $external_vip != '') {
        Notify["Keepalived - openstack_ip_list = ${openstack_ip_list}"]->
        contrail::keepalived::keepalived{'external_ip':
            contrail_ip_list  => $openstack_ip_list,
            virtual_router_id => $external_virtual_router_id,
            vip               => $external_vip
        }
    }

    if ($host_control_ip in $openstack_ip_list and $internal_vip != '') {
        Notify["Keepalived - openstack_ip_list = ${openstack_ip_list}"]->
        contrail::keepalived::keepalived{'internal_ip':
            contrail_ip_list  => $openstack_ip_list,
            virtual_router_id => $internal_virtual_router_id,
            vip               => $internal_vip
        }
    }

    if ($host_control_ip in $config_ip_list and $contrail_internal_vip != '') {
        Notify["Keepalived - openstack_ip_list = ${openstack_ip_list}"]->
        contrail::keepalived::keepalived{'contrail_internal_ip':
            contrail_ip_list  => $config_ip_list,
            virtual_router_id => $contrail_internal_virtual_router_id,
            vip               => $contrail_internal_vip
        }
    }

    if ($host_control_ip in $config_ip_list and $contrail_external_vip != '') {
        Notify["Keepalived - openstack_ip_list = ${openstack_ip_list}"]->
        contrail::keepalived::keepalived{'contrail_external_ip':
            contrail_ip_list  => $config_ip_list,
            virtual_router_id => $contrail_external_virtual_router_id,
            vip               => $contrail_external_vip
        }
    }
}
