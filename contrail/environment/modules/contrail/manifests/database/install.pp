class contrail::database::install (
  $contrail_logoutput = $::contrail::params::contrail_logoutput,
  $host_ip = $::contrail::params::host_ip,
  $database_dir = $::contrail::params::database_dir,
  $contrail_package_name = $::contrail::params::contrail_repo_name,
  $upgrade_needed = $::contrail::params::upgrade_needed,
) {
  if ($upgrade_needed == 1) {
      $cassandra_upgrade_cmd = "/bin/bash /etc/contrail/contrail_setup_utils/upgrade_cassandra.sh ${host_ip} ${database_dir} ${contrail_package_name[0]}"
      file { '/etc/contrail/contrail_setup_utils/upgrade_cassandra.sh':
              ensure  => present,
              mode    => '0755',
              owner   => root,
              group   => root,
              source  => "puppet:///modules/${module_name}/upgrade_cassandra.sh"
      } ->
      exec { 'Upgrade Cassandra to version 2.1 through intermediate version':
          command => $cassandra_upgrade_cmd,
          provider => shell,
          logoutput => $contrail_logoutput,
          before => Package['contrail-openstack-database'],
      } ->
      notify { "executed contrail Upgrade Cassandra Command : ${cassandra_upgrade_cmd}":; } ->
      package {'cassandra':
                ensure => latest,
                configfiles => "replace",
      } ->
      package { 'contrail-openstack-database' :
          ensure => latest,
          notify => Service["supervisor-database"]
      }
  } else {
      package { 'contrail-openstack-database' :
          ensure => latest
      }
  }
  Package['contrail-openstack-database'] ->
  exec { 'Stopping Cassandra till it is correctly configured':
      command => "service cassandra stop",
      provider => shell,
      logoutput => $contrail_logoutput
  }
  if ($lsbdistrelease == "14.04") {
      package { 'default-jre-headless' :
          ensure => latest
      } ->
      Package['contrail-openstack-database']
  }
}
