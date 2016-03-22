class contrail::config::install(
 $contrail_host_roles = $::contrail::params::host_roles,
 $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
 $internal_vip = $::contrail::params::internal_vip,
) {
  # Install a specific version of keepalived in non-ha
  # case also, to support upgrade of contrail software.
  # Below code is not required when keepalive dependency is fixed.
  #
  if ($contrail_internal_vip == "" and ($internal_vip == "" or !('openstack' in $contrail_host_roles))) {

      if ($lsbdistrelease == "14.04") {
          $keepalived_pkg         = '1.2.13-0~276~ubuntu14.04.1'
      } else {
          $keepalived_pkg         = '1:1.2.13-1~bpo70+1'
      }

      package { 'keepalived' :
          ensure => $keepalived_pkg,
      }
      ->
      service { "keepalived" :
          enable => false,
          ensure => stopped,
      }
      Package['keepalived'] -> Package['contrail-openstack-config']
  }

  exec { 'Temporarily delete contrail-openstack-config, contrail-config-openstack' :
          command   => "apt-get -y --force-yes purge contrail-openstack-config contrail-config-openstack",
          provider  => shell,
          logoutput => $contrail_logoutput,
          before => Package['contrail-config'],
  }
  package { 'contrail-config':
    ensure => latest,
    configfiles => "replace",
    before => Package['contrail-openstack-config'],
    notify => Service['supervisor-config']
  }
  package { 'contrail-openstack-config' :
    ensure => latest,
    configfiles => "replace",
    before => Package['contrail-config-openstack'],
    notify => Service['supervisor-config']
  }
  package { 'contrail-config-openstack' :
    ensure => latest,
    configfiles => "replace",
    notify => Service['supervisor-config']
  }

}
