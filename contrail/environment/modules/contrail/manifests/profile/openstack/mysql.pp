# The profile to install an OpenStack specific mysql server
class contrail::profile::openstack::mysql {
  $internal_vip = $::contrail::params::internal_vip

  if ($internal_vip != "" and $internal_vip != undef) {
    class { '::mysql::server':
      root_password                => $::openstack::config::mysql_root_password,
      restart                      => true,
      override_options             => {
	'mysqld'                   => {
	  'bind_address'           => "0.0.0.0",
	  'default-storage-engine' => 'innodb',
	  'wait_timeout'           => '60',
	  'interactive_timeout'    => '60',
	  'lock_wait_timeout'      => '600',
	  'max_connect_errors'     => '10000',

	}

      }
    }

  } else {
    class { '::mysql::server':
      root_password                => $::openstack::config::mysql_root_password,
      restart                      => true,
      override_options             => {
	'mysqld'                   => {
	  'bind_address'           => "0.0.0.0",
	  'default-storage-engine' => 'innodb',
	  'max_connect_errors'     => '10000',
	}

      }
    }

  }


  class { '::mysql::bindings':
    python_enable => true,
    ruby_enable   => true,
  }

  # This class requires Service['mysqld']
  #include contrail::ha_config
#  class {'::contrail::ha_config':
#    require => Service['mysqld']
#  }

  Service['mysqld'] -> Anchor['database-service']

# class { 'mysql::server::account_security': }
}
