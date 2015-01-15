define contrail::lib::report_status(
    $state
) {
    exec { "contrail-status-$state" :
	command => "mkdir -p /etc/contrail/ && wget --post-data=\"\" \"http://$serverip:9002/server_status?server_id=$hostname&state=$state\" && echo contrail-status-$state >> /etc/contrail/contrail_common_exec.out",
	provider => shell,
	unless  => "grep -qx contrail-status-$state /etc/contrail/contrail_common_exec.out",
	logoutput => "true"
    }
}
