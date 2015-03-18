define contrail::lib::report_status(
    $state,
    $contrail_logoutput = false,
) {
    exec { "contrail-status-$state" :
	command => "mkdir -p /etc/contrail/ && wget --post-data=\"\" \"http://puppet:9002/server_status?server_id=$hostname&state=$state\" && echo contrail-status-$state >> /etc/contrail/contrail_common_exec.out",
	provider => shell,
	logoutput => $contrail_logoutput
    }
}
