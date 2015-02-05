#
class cinder::db::sync {

  include cinder::params
  $sync_db = $::contrail::params::sync_db


  if( $sync_db) {
    exec { 'cinder-manage db_sync':
      command     => $::cinder::params::db_sync_command,
      path        => '/usr/bin',
      user        => 'cinder',
      refreshonly => true,
      require     => [File[$::cinder::params::cinder_conf], Class['cinder']],
      logoutput   => 'on_failure',
    }
  } else {
    exec { 'cinder-manage db_sync':
      command     => "touch /tmp/cinder_db_sync",
      path        => '/usr/bin',
      user        => 'cinder',
      refreshonly => true,
      require     => [File[$::cinder::params::cinder_conf], Class['cinder']],
      logoutput   => 'on_failure',
    }
  }
}
