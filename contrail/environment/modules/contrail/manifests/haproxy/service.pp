class contrail::haproxy::service() {
    service { 'haproxy':
        ensure    => 'running',
        enable    => true,
    }
}
