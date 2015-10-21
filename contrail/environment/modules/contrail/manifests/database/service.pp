class contrail::database::service {
    service { [ 'zookeeper', 'supervisor-database', 'contrail-database'] :
        ensure    => running,
        enable    => true,
    }
}
