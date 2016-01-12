class contrail::disable_selinux (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    # disable selinux runtime
    exec { 'selinux-dis-2' :
           command   => 'setenforce 0 || true',
           unless    => 'getenforce | grep -qi disabled',
           provider  => shell,
           logoutput => $contrail_logoutput
    }
    ->
    notify { "executed selinux-dis-2" :; }
}

