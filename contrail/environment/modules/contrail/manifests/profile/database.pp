# == Class: contrail::profile::database
# The puppet module to set up a Contrail database server
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
# [*enable_ceilometer*]
#     Flag to include or exclude ceilometer service as part of openstack module dynamically.
#     (optional) - Defaults to false.
#
class contrail::profile::database (
    $enable_module = $::contrail::params::enable_database,
    $enable_ceilometer = $::contrail::params::enable_ceilometer
) {
    if ($enable_module) {
        contain ::contrail::database
    }
    if ($enable_ceilometer) {
      $controller_address_management = hiera(openstack::controller::address::management)
      $database_ip_list = $::contrail::params::database_ip_list
      $ceilometer_mongo_password = hiera(openstack::ceilometer::mongo::password)
      $ceilometer_password = hiera(openstack::ceilometer::password)
      $ceilometer_meteringsecret = hiera(openstack::ceilometer::meteringsecret)
      $mongodb_bind_address = $contrail::params::host_non_mgmt_ip

      class { '::mongodb::server':
          bind_ip => ['127.0.0.1', $mongodb_bind_address],
      }

      class { '::mongodb::client': }
          mongodb_database { 'ceilometer':
          ensure  => present,
          tries   => 20,
          require => Class['mongodb::server'],
      }

      mongodb_user { 'ceilometer':
          ensure        => present,
          password_hash => mongodb_password('ceilometer', $ceilometer_mongo_password),
          database      => 'ceilometer',
          roles         => ['readWrite', 'dbAdmin'],
          tries         => 10,
          require       => [Class['mongodb::server'], Class['mongodb::client']],
      }

      $dbsync_command = $::ceilometer::params::dbsync_command

      Class['::mongodb::server'] -> Class['::mongodb::client']
   }
}
