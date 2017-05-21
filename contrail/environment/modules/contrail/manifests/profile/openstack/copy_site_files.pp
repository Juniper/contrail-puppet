define copy_site_files ($file = undef) {
  file { $file :
    ensure => present,
    path => "/etc/apache2/sites-available/${file}",
    source => "/tmp/sites-available/${file}"
  }
}

