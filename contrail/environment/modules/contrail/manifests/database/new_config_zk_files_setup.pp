class contrail::database::new_config_zk_files_setup (
  $contrail_logoutput = $::contrail::params::contrail_logoutput,
  $database_index = 1
) {
  # set high session timeout to survive glance led disk activity
  $zk_cfg = { 'zk_cfg' =>
                { 'maxSessionTimeout' => "120000",
                  'autopurge.purgeInterval' => "3",
                },
  }
  $zk_cfg_keys = keys($zk_cfg['zk_cfg'])
  contrail::lib::augeas_conf_set { $zk_cfg_keys:
           config_file => '/etc/zookeeper/conf/zoo.cfg',
           settings_hash => $zk_cfg['zk_cfg'],
           lens_to_use => 'properties.lns',
  }
  ->
  file {'/etc/zookeeper/conf/log4j.properties':
             ensure => present,
  }
  ->
  contrail::lib::augeas_conf_set { 'log4j.appender.ROLLINGFILE.MaxBackupIndex':
          config_file => '/etc/zookeeper/conf/log4j.properties',
          settings_hash => { 'log4j.appender.ROLLINGFILE.MaxBackupIndex' => "11",},
          lens_to_use => 'properties.lns',
  }

  case $::operatingsystem {
          'Ubuntu': {
              file {'/etc/zookeeper/conf/environment':
                   ensure => present,
              }
              ->
              contrail::lib::augeas_conf_set { 'ZOO_LOG4J_PROP':
                  config_file => '/etc/zookeeper/conf/environment',
                  settings_hash => {'ZOO_LOG4J_PROP' => "INFO,CONSOLE,ROLLINGFILE"},
                  lens_to_use => 'properties.lns',
              }
          }
          'Centos', 'Fedora' : {
              file {'/etc/zookeeper/zookeeper-env.sh':
                  ensure => present,
              }
              ->
              file_line { 'Add ZOO_LOG4J_PROP to Zookeeper env':
                path => '/etc/zookeeper/zookeeper-env.sh',
                line => 'export ZOO_LOG4J_PROP=\"INFO,CONSOLE,ROLLINGFILE\"',
              }
          }
  }

  file {'/var/lib/zookeeper/myid':
           ensure => present,
  }
  ->
  file_line { 'Add cfgm_index to Zookeeper ID':
                  path => '/var/lib/zookeeper/myid',
                  line => ${database_index},
  }
  notify { "executed contrail contrail_zk_exec_cmd : ${contrail_zk_exec_cmd}":; }
}
