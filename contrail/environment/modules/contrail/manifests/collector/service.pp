class contrail::collector::service(
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    # Ensure the services needed are running.
    exec { 'redis-del-db-dir':
        command   => 'rm -f /var/lib/redis/dump.rb',
        provider  => shell,
        logoutput => $contrail_logoutput
    } ->
    service { ['redis-server', 'supervisor-analytics'] :
        ensure    => running,
        enable    => true,
    }
}
