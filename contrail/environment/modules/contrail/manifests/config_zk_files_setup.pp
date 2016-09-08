class contrail::config_zk_files_setup (
  $contrail_logoutput = $::contrail::params::contrail_logoutput,
  $zookeeper_conf_dir = $::contrail::params::zookeeper_conf_dir,
  $database_index = 1,
  $zk_myid_file = "${zookeeper_conf_dir}/myid"
) {
  # set high session timeout to survive glance led disk activity
  $zk_cfg = { 'zk_cfg' =>
                { 'maxSessionTimeout' => "120000",
                  'autopurge.purgeInterval' => "3",
                },
  }
  contrail::lib::augeas_conf_set { 'zk_cfg_keys':
           config_file => "${zookeeper_conf_dir}/zoo.cfg",
           settings_hash => $zk_cfg['zk_cfg'],
           lens_to_use => 'properties.lns',
  } ->
  file {"${zookeeper_conf_dir}/log4j.properties":
             ensure => present,
  } ->
  contrail::lib::augeas_conf_set { 'log4j.appender.ROLLINGFILE.MaxBackupIndex':
          config_file => "${zookeeper_conf_dir}/log4j.properties",
          settings_hash => { 'log4j.appender.ROLLINGFILE.MaxBackupIndex' => "11",},
          lens_to_use => 'properties.lns',
  } ->
  file { $zk_myid_file :
      ensure => present,
      mode    => '0755',
      content => "${database_index}",
  }

  case $::operatingsystem {
          'Ubuntu': {
              Contrail::Lib::Augeas_conf_set['log4j.appender.ROLLINGFILE.MaxBackupIndex'] ->
              file {"${zookeeper_conf_dir}/environment":
                   ensure => present,
              } ->
              file_line { 'Add ZOO_LOG4J_PROP to Zookeeper env':
                   path => "${zookeeper_conf_dir}/environment",
                   line => "ZOO_LOG4J_PROP=\"INFO,CONSOLE,ROLLINGFILE\"",
                   match   => 'ZOO_LOG4J_PROP=.*$',
              } ->
              File[$zk_myid_file]
          }
          'Centos', 'Fedora' : {
              Contrail::Lib::Augeas_conf_set['log4j.appender.ROLLINGFILE.MaxBackupIndex'] ->
              file {"${zookeeper_conf_dir}/zookeeper-env.sh":
                  ensure => present,
              } ->
              file_line { 'Add ZOO_LOG4J_PROP to Zookeeper env':
                path => "${zookeeper_conf_dir}/zookeeper-env.sh",
                line => 'export ZOO_LOG4J_PROP=\"INFO,CONSOLE,ROLLINGFILE\"',
              } ->
              File[$zk_myid_file]
          }
  }
}
