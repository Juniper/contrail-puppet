class contrail::config::install(
 $contrail_host_roles = $::contrail::params::host_roles,
 $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
 $internal_vip = $::contrail::params::internal_vip,
 $upgrade_needed = $::contrail::params::upgrade_needed,
) {
  # Install a specific version of keepalived in non-ha
  # case also, to support upgrade of contrail software.
  # Below code is not required when keepalive dependency is fixed.
  #
  if ($contrail_internal_vip == "" and ($internal_vip == "" or !('openstack' in $contrail_host_roles))) {

      if ($::operatingsystem == 'Ubuntu') {
          if ($lsbdistrelease == "14.04") {
              $keepalived_pkg         = '1.2.13-0~276~ubuntu14.04.1'
          } else {
              $keepalived_pkg         = '1:1.2.13-1~bpo70+1'
          }

          package { 'keepalived' :
              ensure => $keepalived_pkg,
          }
      }
      service { "keepalived" :
          enable => false,
          ensure => stopped,
      }
      if defined(Package['keepalived']) {
          Package['keepalived'] -> Package['contrail-openstack-config']
      }
  }

  if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
      $cmd='yum -y remove contrail-openstack-config contrail-config-openstack'
  }
  else {
      $cmd="apt-get -y --force-yes purge contrail-openstack-config contrail-config-openstack"
  }
  if ($upgrade_needed == 1) {
      exec { 'Temporarily delete contrail-openstack-config, contrail-config-openstack' :
          command   => $cmd,
          provider  => shell,
          logoutput => $contrail_logoutput,
      }
      Exec['Temporarily delete contrail-openstack-config, contrail-config-openstack'] -> Package['contrail-config']
  }
  package { 'contrail-config':
    ensure => latest,
    configfiles => "replace",
    notify => Service['supervisor-config']
  } ->
  package { 'contrail-openstack-config' :
    ensure => latest,
    configfiles => "replace",
    notify => Service['supervisor-config']
  } ->
  package { 'contrail-config-openstack' :
    ensure => latest,
    configfiles => "replace",
    notify => Service['supervisor-config']
  }
}
