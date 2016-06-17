# The profile to install an OpenStack specific mysql server
class contrail::profile::openstack::mysql(
  $internal_vip   = $::contrail::params::internal_vip,
  $root_password  = $::contrail::params::mysql_root_password,
  $package_manage = false,
) {

  $override_options = {
    'mysqld' => {
      'bind_address'           => '0.0.0.0',
      'default-storage-engine' => 'innodb',
      'max_connect_errors'     => '10000',
      'max_connections'        => '10000'
    }
  }

  if ($internal_vip != '' and $internal_vip != undef) {
    $extra_options =  {
        'mysqld' => {
            'wait_timeout'           => '60',
            'interactive_timeout'    => '60',
            'lock_wait_timeout'      => '600',
            'max_connections'        => '10000'
        }
    }
  }

  $override_options_hash = merge($extra_options, $override_options)
  class { '::mysql::server':
    root_password    => $root_password,
    restart          => true,
    package_manage   => $package_manage,
    override_options => $override_options_hash
  }

  class { '::mysql::bindings':
    python_enable => true,
    #ruby_enable   => true,
  }
}
