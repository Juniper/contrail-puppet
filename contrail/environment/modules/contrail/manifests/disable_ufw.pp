class contrail::disable_ufw (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    # disable firewall
    exec { 'disable-ufw' :
          command   => 'ufw disable',
          unless    => [ 'test -f /usr/sbin/ufw', 'ufw status | grep -qi inactive'],
          onlyif    => 'test -f /usr/sbin/ufw',
          provider  => shell,
          logoutput => $contrail_logoutput
    }
    ->
    notify { "executed disable_ufw" :; }
}

