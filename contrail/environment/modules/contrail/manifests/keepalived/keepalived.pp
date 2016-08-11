define contrail::keepalived::keepalived (
    $contrail_ip_list = undef,
    $virtual_router_id = undef,
    $vip = undef,
    $host_control_ip = $::contrail::params::host_ip,
) {

    $control_data_intf = get_device_name($host_control_ip)
    $num_nodes = inline_template('<%= @contrail_ip_list.length %>')
    $tmp_index = inline_template('<%= @contrail_ip_list.index(@host_control_ip) %>')
    if ($tmp_index == nil) {
        fail("Host ${host_control_ip} not found in servers of config roles")
    }
    $config_index = $tmp_index + 1

    if ($config_index == 1 ) {
        $keepalived_state = 'MASTER'
        $contrail_garp_master_delay = 5
        $contrail_preempt_delay = 7
    } elsif ($config_index == 2 and $num_nodes > 2 ) {
        $keepalived_state = 'MASTER'
        $contrail_garp_master_delay = 1
        $contrail_preempt_delay = 1
    } else {
        $keepalived_state = 'BACKUP'
        $contrail_garp_master_delay = 1
        $contrail_preempt_delay = 1
    }
    $interface = find_matching_interface($vip)
    $netmask = inline_template("<%= scope.lookupvar('netmask_' + @interface) %>")
    $cidr = convert_netmask_to_cidr($netmask)
    $keepalived_priority = $virtual_router_id - $config_index

    notify { "Keepalived - Setting up vip_${name}":; } ->
    notify { "Keepalived - config_index for ${name} = ${config_index}":; } ->
    keepalived::vrrp::script { "check_haproxy_${name}":
        script   => '/usr/bin/killall -0 haproxy',
        timeout  => '3',
        interval => '1',
        rise     => '2',
        fall     => '2',
    } ->
    keepalived::vrrp::script { "check_peers_${name}":
        script   => '/opt/contrail/bin/chk_ctrldata.sh',
        interval => '1',
        timeout  => '3',
        rise     => '1',
        fall     => '1',
    } ->
    keepalived::vrrp::instance { "VI_${virtual_router_id}":
        interface           => $interface,
        state               => $keepalived_state,
        virtual_router_id   => $virtual_router_id,
        priority            => $keepalived_priority,
        auth_type           => 'PASS',
        auth_pass           => 'secret',
        virtual_ipaddress   => $vip,
        net_mask            => $cidr,
        garp_master_refresh => 1,
        garp_master_repeat  => 3,
        garp_master_delay   => $contrail_garp_master_delay,
        preempt_delay       => $contrail_preempt_delay,
        vmac_xmit_base      => true,
        track_interface     => $control_data_intf,
        track_script        => ["check_haproxy_${name}","check_peers_${name}"],
    } ->
    Class['::keepalived']

    # for contrail HA, use correct keepalived version for centos
   if ($lsbdistrelease == "14.04") {
        $pkg_ensure = '1.2.13-0~276~ubuntu14.04.1'
   } elsif ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
        $pkg_ensure = 'present'
   } else {
        $pkg_ensure = '1:1.2.13-1~bpo70+1'
   }

    class { '::keepalived' :
        pkg_ensure          => $pkg_ensure
    }

    contain ::keepalived
}
