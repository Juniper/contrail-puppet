#source ha proxy files
define contrail::lib::haproxy_cfg(
    $server_id,
    $contrail_logoutput = false,
) {
  file { '/etc/haproxy/haproxy.cfg':
    ensure => present,
    mode   => '0755',
    owner  => root,
    group  => root,
    source => "puppet:///modules/${module_name}/${server_id}.cfg"
  }
  contrail::lib::augeas_conf_set { 'ENABLED':
      config_file => '/etc/default/haproxy',
      settings_hash => { 'ENABLED' => '1',},
      lens_to_use => 'properties.lns',
  }
  service { 'haproxy' :
    ensure  => running,
    enable  => true,
    require => [File['/etc/default/haproxy'], File['/etc/haproxy/haproxy.cfg']],
  }
}
