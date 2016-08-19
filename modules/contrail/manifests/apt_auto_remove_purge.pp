class contrail::apt_auto_remove_purge (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    exec { "apt_auto_remove_purge":
        command => "apt-get autoremove -y --purge",
        provider => shell,
        logoutput => $contrail_logoutput
    }
    ->
    notify { "executed apt autoremove purge" :; }
}

