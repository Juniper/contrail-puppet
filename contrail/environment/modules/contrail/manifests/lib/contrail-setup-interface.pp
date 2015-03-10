define contrail::lib::contrail-setup-interface(
	$contrail_device,
	$contrail_members,
	$contrail_bond_opts,
	$contrail_ip,
	$contrail_gw,
        $contrail_logoutput = false,
    ) {

    package {'ifenslave': ensure => present}
    package {'contrail-setup': ensure => present}

    $contrail_member_list = $contrail_members
	$contrail_intf_member_list_for_shell = inline_template('<%= contrail_member_list.map{ |ip| "#{ip}" }.join(" ") %>')


    if($contrail_members == "" ) {

	$exec_cmd = "/opt/contrail/bin/setup-vnc-interfaces.py --device $contrail_device --ip $contrail_ip"
    } else {
	$exec_cmd = "/opt/contrail/bin/setup-vnc-interfaces.py --device $contrail_device --members $contrail_intf_member_list_for_shell --bond-opts \"$contrail_bond_opts\" --ip $contrail_ip"
    }

    if ($contrail_gw != "" ) {
	$gw_suffix = " --gw $contrail_gw && echo setup-intf${contrail_device} >> /etc/contrail/contrail_common_exec.out"
	$exec_full_cmd = "${exec_cmd}${gw_suffix}"
     } else     {
	$gw_suffix =  " && echo setup-intf${contrail_device} >> /etc/contrail/contrail_common_exec.out"
	$exec_full_cmd = "${exec_cmd}${gw_suffix}"
    }

    notify { "command executed is $exec_full_cmd":; }

    exec { "setup-intf-$contrail_device":
	    command => $exec_full_cmd,
	    provider => shell,
	    logoutput => $contrail_logoutput,
	require=> [Package["ifenslave"], Package["contrail-setup"]],
	    unless  => "grep -qx setup-intf${contrail_device} /etc/contrail/contrail_common_exec.out"
    }
}
