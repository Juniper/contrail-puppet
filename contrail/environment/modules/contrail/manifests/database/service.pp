class contrail::database::service (
  $zookeeper_conf_dir = $::contrail::params::zookeeper_conf_dir,
){
    service { 'zookeeper':
        ensure => running,
        enable => true,
        subscribe => File["${zookeeper_conf_dir}/zoo.cfg"],
    }
    ->
    service { ['supervisor-database', 'contrail-database'] :
        ensure    => running,
        enable    => true,
    }
}
