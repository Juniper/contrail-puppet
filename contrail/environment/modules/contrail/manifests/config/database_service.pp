class contrail::config::database_service {
    # enable zookeeper svc so that picked by systemctl
    if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
        exec {"chkconfig-zookeeper" :
            command  => "chkconfig zookeeper on",
            provider => shell
        }
        ->
        Service['zookeeper']
    }
    service { 'zookeeper':
        ensure => running,
        enable => true,
        subscribe => File['/etc/zookeeper/conf/zoo.cfg'],
    }
    ->
    service { 'contrail-database' :
        ensure    => running,
        enable    => true
    }
}
