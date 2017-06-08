class contrail::database::service (
  $zookeeper_conf_dir = $::contrail::params::zookeeper_conf_dir,
){
    service { ['supervisor-database', 'contrail-database'] :
        ensure    => running,
        enable    => true,
    }
}
