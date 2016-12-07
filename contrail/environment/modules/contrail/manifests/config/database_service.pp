class contrail::config::database_service (
  $zookeeper_conf_dir = $::contrail::params::zookeeper_conf_dir,
){
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
        subscribe => File["${zookeeper_conf_dir}/zoo.cfg"],
    }
    ->
    service { 'contrail-database' :
        ensure    => running,
        enable    => true
    }
}
