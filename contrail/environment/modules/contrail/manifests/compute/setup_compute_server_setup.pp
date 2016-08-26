class contrail::compute::setup_compute_server_setup (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    file { '/opt/contrail/bin/compute-server-setup.sh':
            ensure  => present,
            mode    => '0755',
            owner   => root,
            group   => root,
            require => File['/etc/contrail/ctrl-details'],
    }
    ->
    exec { 'setup-compute-server-setup' :
            command   => '/opt/contrail/bin/compute-server-setup.sh; echo setup-compute-server-setup >> /etc/contrail/contrail_compute_exec.out',
            unless    => 'grep -qx setup-compute-server-setup /etc/contrail/contrail_compute_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
    }
}
