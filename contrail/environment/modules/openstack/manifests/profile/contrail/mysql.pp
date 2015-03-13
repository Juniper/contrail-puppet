# The profile to install an OpenStack specific mysql server
class openstack::profile::contrail::mysql {
  class { '::mysql::server':
    root_password                => $::openstack::config::mysql_root_password,
    restart                      => true,
    override_options             => {
      'mysqld'                   => {
        'bind_address'           => "0.0.0.0",
        'default-storage-engine' => 'innodb',
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

#  Service['mysqld'] -> Anchor['database-service']

# class { 'mysql::server::account_security': }
}
