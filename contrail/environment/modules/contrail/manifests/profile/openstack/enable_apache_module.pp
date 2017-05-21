# enable specified apache2 modules and sites
define enable_apache_module ($module = undef) {
  exec { "/usr/sbin/a2enmod $module":
    unless => "/bin/readlink -e /etc/apache2/mods-enabled/$module",
  }
  notify { "executed enable-module $module" : }
}

#$mods = {
#  'headers' => { module => 'headers' },
#  'passenger' => { module => 'passenger' },
#  'ssl' => { module => 'ssl' },
#  'socache_shmcb' => { module => 'socache_shmcb' }
#}

#define enable_apache_site ($site = undef) {
#  exec { "/usr/sbin/a2ensite $site":
#    unless => "/bin/readlink -e /etc/apache2/sites-enabled/$site",
#  }
#  notify { "executed enable-site $site" : }
#}

#$sites = {
#  'smgr' => { site => 'smgr' },
#  'default-ssl' => { site => 'default-ssl' },
#  'puppetmaster' => { site => 'puppetmaster' },
#  '000-default' => { site => '000-default' }
#}

#define copy_site_files ($file = undef) {
#  file { "site_conf_files":
#    ensure => present,
#    path => "/etc/apache2/sites-available/${file}",
#    source => "/tmp/sites-available/${file}"
#  }
#}

#create_resources(copy_site_files, $sites)
#create_resources(enable_apache_module, $mods)
#create_resources(enable_apache_site, $sites)
#Copy_site_files <| |> -> Enable_apache_module <| |> -> Enable_apache_site <| |> ~>
#Service['apache2']

