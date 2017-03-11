class contrail::flush_iptables (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
        #Disable iptables
        service { 'iptables' :
            ensure => stopped,
            enable => false,
        } -> Exec['iptables --flush']
    }
    # Flush ip tables.
    exec { 'iptables --flush':
      provider  => shell,
      onlyif    => "test -f /sbin/iptables",
      logoutput => $contrail_logoutput }
    ->
    notify { "flushed iptables" :; }
}

