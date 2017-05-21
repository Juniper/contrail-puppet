define enable_apache_site ($site = undef) {
  exec { "/usr/sbin/a2ensite $site":
    unless => "/bin/readlink -e /etc/apache2/sites-enabled/$site",
  }
  notify { "executed enable-site $site" : }
}

