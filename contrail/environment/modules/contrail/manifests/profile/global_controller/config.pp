# == Class: global_controller::config
#
# This class is used to manage arbitrary global_controller configurations.
#

class contrail::profile::global_controller::config (
    $database_ip_list =  $::contrail::params::database_ip_list,
    $keystone_mgmt_ip = $::contrail::params::keystone_mgmt_ip,
    $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $openstack_ip_to_use = $::contrail::params::openstack_ip_to_use,
    $allowed_hosts     = $::contrail::params::os_mysql_allowed_hosts,
    $os_mysql_service_password = $::contrail::params::os_mysql_service_password,
) {

  class {'::contrail::profile::global_controller::db::mysql':
    password => $os_mysql_service_password,
    allowed_hosts => $allowed_hosts,
  } ->

  file { '/etc/ukai/':
    ensure => directory,
    owner  => 'ukai',
    group  => 'ukai',
    mode   => '0770',
  } ->

  file { '/etc/ukai/gohan.yaml':
      ensure  => $ensure_storage,
      path    => '/etc/ukai/gohan.yaml',
      content => template("${module_name}/gohan.yaml.erb"),
  }
}
