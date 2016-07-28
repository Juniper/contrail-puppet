class contrail::profile::openstack::neutron(
  $host_control_ip   = $::contrail::params::host_ip,
  $allowed_hosts     = $::contrail::params::os_mysql_allowed_hosts,
  $service_password  = $::contrail::params::os_mysql_service_password,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
  $contrail_logoutput = $::contrail::params::contrail_logoutput,
  $host_roles = $::contrail::params::host_roles,
) {

  $database_credentials = join([$service_password, "@", $host_control_ip],'')
  $keystone_db_conn = join(["mysql://neutron:",$database_credentials,"/neutron"],'')

  class {'::neutron::db::mysql':
    password      => $service_password,
    allowed_hosts => $allowed_hosts,
  }
  if ($::operatingsystem == 'Ubuntu') {
      package { 'neutron-server': ensure => present }
  }
  if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
     package { 'openstack-neutron': ensure => present }
  }
  class {'::contrail::profile::neutron_db_sync':
    database_connection => $keystone_db_conn
 }
 if (!('config' in $host_roles)) {
     exec { 'stop_neutron_server_service':
          command => "service neutron-server stop",
          provider => shell,
          logoutput => $contrail_logoutput,
     }
 }
}
