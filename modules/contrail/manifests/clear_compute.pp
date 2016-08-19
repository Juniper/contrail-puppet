class contrail::clear_compute (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    exec { 'clear_compute' :
	command => 'rm -f /etc/contrail/contrail_compute_exec.out',
	provider => shell,
	logoutput => $contrail_logoutput
    }
    ->
    notify { "executed clear_compute" :; }
}

