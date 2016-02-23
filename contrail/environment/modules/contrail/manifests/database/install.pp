class contrail::database::install (
  $contrail_logoutput = $::contrail::params::contrail_logoutput,
  $host_ip = $::contrail::params::host_ip,
  $database_dir = $::contrail::params::database_dir,
  $contrail_package_name = $::contrail::params::contrail_repo_name,
) {
  if ($lsbdistrelease == "14.04") {
      package { 'default-jre-headless' :
      ensure => latest,
      before => Package['contrail-openstack-database']
    }
  }
  $cassandra_upgrade_cmd = "/bin/bash /etc/contrail/contrail_setup_utils/upgrade_cassandra.sh ${host_ip} ${database_dir} ${contrail_package_name[0]}"
  file { '/etc/contrail/contrail_setup_utils/upgrade_cassandra.sh':
              ensure  => present,
              mode    => '0755',
              owner   => root,
              group   => root,
              source  => "puppet:///modules/${module_name}/upgrade_cassandra.sh"
  }
  ->
  exec { 'Upgrade Cassandra to version 2.1 through intermediate version':
      command => $cassandra_upgrade_cmd,
      provider => shell,
      logoutput => $contrail_logoutput,
      before => Package['contrail-openstack-database'],
  }
  ->
  notify { "executed contrail contrail_zk_exec_cmd : ${cassandra_upgrade_cmd}":; }
  package { 'contrail-openstack-database' :
    ensure => latest
  }
}
