class contrail::database::config_zk_files_setup (
  $contrail_zk_exec_cmd = false,
  $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
  if ( $contrail_zk_exec_cmd ) {
    file { '/etc/contrail/contrail_setup_utils/config-zk-files-setup.sh':
              ensure  => present,
              mode    => '0755',
              owner   => root,
              group   => root,
              source  => "puppet:///modules/${module_name}/config-zk-files-setup.sh"
    }
    ->
    # set high session timeout to survive glance led disk activity
    exec { 'setup-config-zk-files-setup' :
            command   => $contrail_zk_exec_cmd,
            unless    => 'grep -qx setup-config-zk-files-setup /etc/contrail/contrail-config-exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
    }
    ->
    notify { "executed contrail contrail_zk_exec_cmd : ${contrail_zk_exec_cmd}":; }
  }
}
