class contrail::profile::openstack::neutron(
  $host_control_ip   = $::contrail::params::host_ip,
  $allowed_hosts     = $::contrail::params::os_mysql_allowed_hosts,
  $service_password  = $::contrail::params::os_mysql_service_password,
  $neutron_pkg_name  = $::contrail::params::neutron_pkg_name,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
) {

  $database_credentials = join([$service_password, "@", $host_control_ip],'')
  $keystone_db_conn = join(["mysql://neutron:",$database_credentials,"/neutron"],'')

  package { $neutron_pkg_name :
    ensure => present
  }
  class {'::neutron::db::mysql':
    password      => $service_password,
    allowed_hosts => $allowed_hosts,
  } ->

  Package [$neutron_pkg_name] ->

  class {'::contrail::profile::neutron_db_sync':
    database_connection => $keystone_db_conn
 }
}
