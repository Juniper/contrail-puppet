class contrail::flush_iptables (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    # Flush ip tables.
    exec { 'iptables --flush': provider => shell, logoutput => $contrail_logoutput }
    ->
    notify { "flushed iptables" :; }
}

