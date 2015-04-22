define contrail::lib::contrail-upgrade(
    $contrail_upgrade = false,
    $contrail_logoutput = false,
    ) {

    notify { "**** $module_name - contrail_upgrade= $contrail_upgrade": ; }

    if ($contrail_upgrade == true) {
	exec { "clear_out_files" :
	    command   => "rm -f /etc/contrail/contrail*.out && rm -f /opt/contrail/contrail_packages/exec-contrail-setup-sh.out && echo reset_provision >> /etc/contrail/contrail_common_exec.out",
	    unless  => "grep -qx reset_provision  /etc/contrail/contrail_common_exec.out",
	    provider => shell,
	    logoutput => $contrail_logoutput
	}

    }


}
