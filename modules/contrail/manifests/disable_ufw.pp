class contrail::disable_ufw (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    # disable firewall
    exec { 'disable-ufw' :
          command   => 'ufw disable',
          unless    => 'ufw status | grep -qi inactive',
          provider  => shell,
          logoutput => $contrail_logoutput
    }
    ->
    notify { "executed disable_ufw" :; }
}

