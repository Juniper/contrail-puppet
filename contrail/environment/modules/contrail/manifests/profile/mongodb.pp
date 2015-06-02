# == Class: contrail::profile::mongodb
# The puppet module to set up mongodb::server and mongodb::client on database node
#
#
class contrail::profile::mongodb {
      $controller_address_management = hiera(openstack::controller::address::management)
      $database_ip_list = $::contrail::params::database_ip_list
      $ceilometer_mongo_password = hiera(openstack::ceilometer::mongo::password)
      $ceilometer_password = hiera(openstack::ceilometer::password)
      $ceilometer_meteringsecret = hiera(openstack::ceilometer::meteringsecret)
      $mongodb_bind_address = $contrail::params::host_non_mgmt_ip

      class { '::mongodb::server':
          bind_ip => ['127.0.0.1', $mongodb_bind_address],
          replset => 'rs-ceilometer',
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

      Class['::mongodb::server'] -> Class['::mongodb::client']
}
