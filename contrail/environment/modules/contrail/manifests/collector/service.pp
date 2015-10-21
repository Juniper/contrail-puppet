class contrail::collector::service(
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    # Ensure the services needed are running.
    exec { 'redis-del-db-dir':
        command   => 'rm -f /var/lib/redis/dump.rb && service redis-server restart && echo redis-del-db-dir /etc/contrail/contrail-collector-exec.out',
        unless    => 'grep -qx redis-del-db-dir /etc/contrail/contrail-collector-exec.out',
        provider  => shell,
        logoutput => $contrail_logoutput
    } ->
    service { 'supervisor-analytics' :
        ensure    => running,
        enable    => true,
        subscribe => [ File['/etc/contrail/contrail-collector.conf'],
                        File['/etc/contrail/contrail-query-engine.conf'],
                        File['/etc/contrail/contrail-analytics-api.conf'] ],
    }
}
