define contrail::lib::report_status(
    $state
) {
    if ! defined(Package['curl']) {
	package { 'curl' : ensure => present,}
    }
    exec { "contrail-status-$state" :
	command => "mkdir -p /etc/contrail/ && curl -X PUT \"http://$serverip:9002/server_status?server_id=$hostname&state=$state\" && echo contrail-status-$state >> /etc/contrail/contrail_common_exec.out",
	provider => shell,
    require => Package["curl"],
	unless  => "grep -qx contrail-status-$state /etc/contrail/contrail_common_exec.out",
	logoutput => "true"
    }
}
