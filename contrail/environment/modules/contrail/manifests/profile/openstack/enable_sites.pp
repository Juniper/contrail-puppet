class contrail::profile::openstack::enable_sites () {

  #$files = $site_names

  $mods = {
    'headers' => { module => 'headers' },
    'passenger' => { module => 'passenger' },
    'ssl' => { module => 'ssl' },
    'socache_shmcb' => { module => 'socache_shmcb' }
  }

  $sites = {
    'smgr' => { site => 'smgr' },
    #'default-ssl' => { site => 'default-ssl' },
    'puppetmaster' => { site => 'puppetmaster' },
    '000-default' => { site => '000-default' }
  }

  $files = {
    '000-default' => { file => '000-default.conf' },
    'puppetmaster' => { file => 'puppetmaster.conf' },
    'smgr' => { file => 'smgr.conf' }
  }

  create_resources(enable_apache_module, $mods)
  create_resources(copy_site_files, $files)
  create_resources(enable_apache_site, $sites)
  Copy_site_files <| |> -> Enable_apache_module <| |> -> Enable_apache_site <| |> ~>
  Service['apache2']

}
