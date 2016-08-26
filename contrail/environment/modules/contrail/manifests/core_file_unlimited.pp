class contrail::core_file_unlimited (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    # execute core-file-unlimited
    exec { 'core-file-unlimited' :
           command   => 'ulimit -c unlimited',
           unless    => 'ulimit -c | grep -qi unlimited',
           provider  => shell,
           logoutput => $contrail_logoutput
    }
}

