class contrail::config::install() {

  package { 'contrail-openstack-config' :
    ensure => latest
  }

}
