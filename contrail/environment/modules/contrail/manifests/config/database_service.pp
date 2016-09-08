class contrail::config::database_service {
    service { 'zookeeper':
        ensure => running,
        enable => true,
        subscribe => File['/etc/zookeeper/conf/zoo.cfg'],
    }
}
