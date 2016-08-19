class contrail::database::service {
    service { 'zookeeper':
        ensure => running,
        enable => true,
        subscribe => File['/etc/zookeeper/conf/zoo.cfg'],
    }
    ->
    service { ['supervisor-database', 'contrail-database'] :
        ensure    => running,
        enable    => true,
    }
}
