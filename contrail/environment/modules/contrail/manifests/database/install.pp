class contrail::database::install (
  $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
  if ($lsbdistrelease == "14.04") {
      package { 'default-jre-headless' :
      ensure => latest,
      before => Package['contrail-openstack-database']
    }
  }
  package { 'contrail-openstack-database' :
    ensure => latest
  }
}
