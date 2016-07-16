class contrail::control::service() {
    if ($::operatingsystem == 'Ubuntu') {
        service { 'supervisor-dns' :
            ensure    => running,
            enable    => true,
        }
    }
    service { 'supervisor-control' :
        ensure    => running,
        enable    => true,
    }
    ->
    service { 'contrail-named' :
        ensure    => running,
        enable    => true,
    }
}
