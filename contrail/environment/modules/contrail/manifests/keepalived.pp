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
    include ::contrail::params
    #$vip = undef
    #$ip_list = undef

    notify { "Keepalived - host_control_ip = ${host_control_ip}":; }
    notify { "Keepalived - config_ip_list = ${config_ip_list}":; }
    notify { "Keepalived - internal_vip = ${internal_vip}":; }
    notify { "Keepalived - contrail_internal_vip = ${contrail_internal_vip}":; }
    notify { "Keepalived - internal_virtual_router_id = ${internal_virtual_router_id}":; }
    notify { "Keepalived - contrail_virtual_router_id = ${contrail_virtual_router_id}":; }
    notify { "Keepalived - openstack_ip_list = ${openstack_ip_list}":; }

    $control_data_intf = get_device_name($host_control_ip)

    if ($host_control_ip in $openstack_ip_list and $external_vip != '') {

        notify { 'Keepalived - Setting up external_vip ':; }
        $e_num_nodes = inline_template('<%= @openstack_ip_list.length %>')
        $e_tmp_index = inline_template('<%= @openstack_ip_list.index(@host_control_ip) %>')
        if ($e_tmp_index == nil) {
            fail('Host $host_control_ip not found in servers of config roles')
        }

        $e_config_index = $e_tmp_index + 1
        notify { "Keepalived - e_config_index = ${e_config_index}":; }

        if ($e_config_index == 1 ) {
            $e_keepalived_state = 'MASTER'
            $e_contrail_garp_master_delay = 5
            $e_contrail_preempt_delay = 7
        }
        elsif ($e_config_index ==2 and $e_num_nodes > 2 ) {
            $e_keepalived_state = 'MASTER'
            $e_contrail_garp_master_delay = 1
            $e_contrail_preempt_delay = 1
        }
        else {
            $e_keepalived_state = 'BACKUP'
            $e_contrail_garp_master_delay = 1
            $e_contrail_preempt_delay = 1
        }

        include ::keepalived


        $e_interface = find_matching_interface($external_vip)
        $e_netmask = inline_template("<%= scope.lookupvar('netmask_' + @e_interface) %>")
        $e_cidr = convert_netmask_to_cidr($e_netmask)

        $e_keepalived_priority = $external_virtual_router_id - $e_config_index

        keepalived::vrrp::script { 'check_haproxy_external_vip':
            script   => '/usr/bin/killall -0 haproxy',
            timeout  => '3',
            interval => '1',
            rise     => '2',
            fall     => '2',
        }

        keepalived::vrrp::script { 'check_peers_external_vip':
            script   => '/opt/contrail/bin/chk_ctrldata.sh',
            interval => '1',
            timeout  => '3',
            rise     => '1',
            fall     => '1',

        }
        keepalived::vrrp::instance { "VI_${external_virtual_router_id}":
            interface           => $e_interface,
            state               => $e_keepalived_state,
            virtual_router_id   => $external_virtual_router_id,
            priority            => $e_keepalived_priority,
            auth_type           => 'PASS',
            auth_pass           => 'secret',
            virtual_ipaddress   => $external_vip,
            net_mask            => $e_cidr,
            garp_master_refresh => 1,
            garp_master_repeat  => 3,
            garp_master_delay   => $e_contrail_garp_master_delay,
            preempt_delay       => $e_contrail_preempt_delay,
            vmac_xmit_base      => true,
            track_interface     => $control_data_intf,
            track_script        => ['check_haproxy_external_vip','check_peers_external_vip'],
        }
    }


    if ($host_control_ip in $openstack_ip_list and $internal_vip != '') {
        include ::keepalived

        $i_interface = find_matching_interface($internal_vip)
        $i_netmask = inline_template("<%= scope.lookupvar('netmask_' + @i_interface) %>")
        $i_cidr = convert_netmask_to_cidr($i_netmask)

        notify { 'Keepalived - Setting up internal_vip':; }
        $i_num_nodes = inline_template('<%= @openstack_ip_list.length %>')
        $i_tmp_index = inline_template('<%= @openstack_ip_list.index(@host_control_ip) %>')
        if ($i_tmp_index == nil) {
            fail("Host ${host_control_ip} not found in servers of config roles")
        }

        $i_config_index = $i_tmp_index + 1
        notify { "Keepalived - i_config_index = ${i_config_index}":; }

        if ($i_config_index == 1 ) {
            $i_keepalived_state = 'MASTER'
            $i_contrail_garp_master_delay = 5
            $i_contrail_preempt_delay = 7
        }
        elsif ($i_config_index ==2 and $i_num_nodes > 2 ) {
            $i_keepalived_state = 'MASTER'
            $i_contrail_garp_master_delay = 1
            $i_contrail_preempt_delay = 1
        }
        else {
            $i_keepalived_state = 'BACKUP'
            $i_contrail_garp_master_delay = 1
            $i_contrail_preempt_delay = 1
        }

        $i_keepalived_priority = $internal_virtual_router_id - $i_config_index
        keepalived::vrrp::script { 'check_haproxy_internal_vip':
            script   => '/usr/bin/killall -0 haproxy',
            timeout  => '3',
            interval => '1',
            rise     => '2',
            fall     => '2',
        }

        keepalived::vrrp::script { 'check_peers_internal_vip':
            script   => '/opt/contrail/bin/chk_ctrldata.sh',
            interval => '1',
            timeout  => '3',
            rise     => '1',
            fall     => '1',
        }

        keepalived::vrrp::instance { "VI_${internal_virtual_router_id}":
            interface           => $i_interface,
            state               => $i_keepalived_state,
            virtual_router_id   => $internal_virtual_router_id,
            priority            => $i_keepalived_priority,
            auth_type           => 'PASS',
            auth_pass           => 'secret',
            virtual_ipaddress   => $internal_vip,
            net_mask            => $i_cidr,
            garp_master_refresh => 1,
            garp_master_repeat  => 3,
            garp_master_delay   => $i_contrail_garp_master_delay,
            preempt_delay       => $i_contrail_preempt_delay,
            vmac_xmit_base      => true,
            track_interface     => $control_data_intf,
            track_script        => ['check_haproxy_internal_vip','check_peers_internal_vip'],
        }
    }


    if ($host_control_ip in $config_ip_list and $contrail_internal_vip != '') {
        include ::keepalived

        $ci_num_nodes = inline_template('<%= @config_ip_list.length %>')
        $ci_tmp_index = inline_template('<%= @config_ip_list.index(@host_control_ip) %>')
        notify { 'Keepalived - Setting up contrail_internal_vip':; }

        if ($ci_tmp_index == nil) {
            fail("Host ${host_control_ip} not found in servers of config roles")
        }

        $ci_config_index = $ci_tmp_index + 1
        notify { "Keepalived - ci_config_index = ${ci_config_index}":; }

        if ($ci_config_index == 1 ) {
            $ci_keepalived_state = 'MASTER'
            $ci_contrail_garp_master_delay = 5
            $ci_contrail_preempt_delay = 7
        }
        elsif ($ci_config_index ==2 and $ci_num_nodes > 2 ) {
            $ci_keepalived_state = 'MASTER'
            $ci_contrail_garp_master_delay = 1
            $ci_contrail_preempt_delay = 1
        }
        else {
            $ci_keepalived_state = 'BACKUP'
            $ci_contrail_garp_master_delay = 1
            $ci_contrail_preempt_delay = 1
        }



        $ci_keepalived_priority = $contrail_internal_virtual_router_id - $ci_config_index

        $ci_interface = find_matching_interface($contrail_internal_vip)
        $ci_netmask = inline_template("<%= scope.lookupvar('netmask_' + @ci_interface) %>")
        $ci_cidr = convert_netmask_to_cidr($ci_netmask)

        keepalived::vrrp::script { 'check_haproxy_contrail_internal_vip':
            script   => '/usr/bin/killall -0 haproxy',
            timeout  => '3',
            interval => '1',
            rise     => '2',
            fall     => '2',
        }

        keepalived::vrrp::script { 'check_peers_contrail_internal_vip':
            script   => '/opt/contrail/bin/chk_ctrldata.sh',
            interval => '1',
            timeout  => '3',
            rise     => '1',
            fall     => '1',
        }

        keepalived::vrrp::instance { "VI_${contrail_internal_virtual_router_id}":
            interface           => $ci_interface,
            state               => $::contrail::params::keepalived_state,
            virtual_router_id   => $contrail_internal_virtual_router_id,
            priority            => $ci_keepalived_priority,
            auth_type           => 'PASS',
            auth_pass           => 'secret',
            virtual_ipaddress   => $contrail_internal_vip,
            net_mask            => $ci_cidr,
            garp_master_refresh => 1,
            garp_master_repeat  => 3,
            garp_master_delay   => $ci_contrail_garp_master_delay,
            preempt_delay       => $ci_contrail_preempt_delay,
            vmac_xmit_base      => true,
            track_interface     => $control_data_intf,
            track_script        => ['check_haproxy_contrail_internal_vip','check_peers_contrail_internal_vip'],
        }
    }

    if ($host_control_ip in $config_ip_list and $contrail_external_vip != '') {
        notify { 'Keepalived - Setting up contrail_external_vip':; }
        include ::keepalived

        $ce_num_nodes = inline_template('<%= @config_ip_list.length %>')
        $ce_tmp_index = inline_template('<%= @config_ip_list.index(@host_control_ip) %>')
        if ($ce_tmp_index == nil) {
            fail("Host ${host_control_ip} not found in servers of config roles")
        }

        $ce_config_index = $ce_tmp_index + 1
        notify { "Keepalived - ce_config_index = ${ce_config_index}":; }

        if ($ce_config_index == 1 ) {
            $ce_keepalived_state = 'MASTER'
            $ce_contrail_garp_master_delay = 5
            $ce_contrail_preempt_delay = 7
        }
        elsif ($ce_config_index ==2 and $ce_num_nodes > 2 ) {
            $ce_keepalived_state = 'MASTER'
            $ce_contrail_garp_master_delay = 1
            $ce_contrail_preempt_delay = 1
        }
        else {
            $ce_keepalived_state = 'BACKUP'
            $ce_contrail_garp_master_delay = 1
            $ce_contrail_preempt_delay = 1
        }

        $ce_keepalived_priority = $contrail_external_virtual_router_id - $ce_config_index

        $ce_interface = find_matching_interface($contrail_external_vip)
        $ce_netmask = inline_template("<%= scope.lookupvar('netmask_' + @ce_interface) %>")
        $ce_cidr = convert_netmask_to_cidr($ce_netmask)

        keepalived::vrrp::script { 'check_haproxy_contrail_external_vip':
            script   => '/usr/bin/killall -0 haproxy',
            timeout  => '3',
            interval => '1',
            rise     => '2',
            fall     => '2',
        }

        keepalived::vrrp::script { 'check_peers_contrail_external_vip':
            script   => '/opt/contrail/bin/chk_ctrldata.sh',
            interval => '1',
            timeout  => '3',
            rise     => '1',
            fall     => '1',
        }

        keepalived::vrrp::instance { "VI_${contrail_external_virtual_router_id}":
            interface           => $ce_interface,
            state               => $::contrail::params::keepalived_state,
            virtual_router_id   => $contrail_external_virtual_router_id,
            priority            => $ce_keepalived_priority,
            auth_type           => 'PASS',
            auth_pass           => 'secret',
            virtual_ipaddress   => $contrail_external_vip,
            net_mask            => $ce_cidr,
            garp_master_refresh => 1,
            garp_master_repeat  => 3,
            garp_master_delay   => $ce_contrail_garp_master_delay,
            preempt_delay       => $ce_contrail_preempt_delay,
            vmac_xmit_base      => true,
            track_interface     => $control_data_intf,
            track_script        => ['check_haproxy_contrail_external_vip','check_peers_contrail_external_vip'],
        }
    }
}
