class contrail::collector::service(
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
        $redis_service = 'redis'
    }
    if ($::operatingsystem == 'Ubuntu') {
        $redis_service = 'redis-server'
    }
    # Ensure the services needed are running.
    exec { 'redis-del-db-dir':
        command   => 'rm -f /var/lib/redis/dump.rb',
        provider  => shell,
        logoutput => $contrail_logoutput
    } ->
    service { [$redis_service, 'supervisor-analytics'] :
        ensure    => running,
        enable    => true,
    }
}
