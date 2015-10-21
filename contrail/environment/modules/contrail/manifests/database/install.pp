class contrail::database::install (
  $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
  package { 'contrail-openstack-database' :
    ensure => latest
  }
}
