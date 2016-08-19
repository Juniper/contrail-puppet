define contrail::lib::setup_dpdk_depends(
    $contrail_logoutput = false,
    $enable_dpdk = $::contrail::params::enable_dpdk,
    $contrail_repo_name = $::contrail::params::contrail_repo_name,
)
{
  if ($enable_dpdk) {

    if ($::operatingsystem == "Ubuntu") {


        notify { "settting up DPDK Repo":; }
        ->
        apt::source { 'contrail-dpdk-depends':
          location => "http://puppet/contrail/repo/${contrail_repo_name[0]}/dpdk_depends",
          repos    => 'main',
          release  => 'contrail-dpdk-depends',
        }
        ->
        apt::pin { 'contrail-dpdk-depreds-repo_preferences':
         priority => '1000',
         codename => 'contrail-dpdk-depends'
        }


        #for setting up the repo without apt at any stage
        #as there given the stages for now
        #apt module can only be used in first stage.

/*
        file { '/etc/apt/sources.list.d/contrail_dpdk.list' :
            ensure  => present,
            content => template("${module_name}/contrail_dpdk_depends_sources.list.erb")
        }
        ->
        file { '/etc/apt/preferences.d/contrail_dpdk_preferences.pref' :
            ensure  => present,
            content => template("${module_name}/contrail_dpdk_preferences.pref")
        }
        ->
        exec { 'apt_get_update' :
          command   => 'apt-get update',
          provider  => 'shell',
          logoutput => $contrail_logoutput
        }

*/

        #for setting up a local repo of dpdk-packages
/*
        package { dpdk-depends-packages :
          ensure => present,
        }
        ->
        file_line { "add_dpdk_depends":
          path  => '/etc/apt/sources.list',
                line  => 'deb file:/opt/contrail/contrail_install_repo_dpdk ./',
        }
        ->
        exec { 'scan_packages' :
          command   => 'dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz',
          provider  => 'shell',
          cwd => '/opt/contrail/contrail_install_repo_dpdk',
          logoutput => $contrail_logoutput,
        }
        ->
        exec { 'apt_get_update' :
          command   => 'apt-get update',
          provider  => 'shell',
          logoutput => $contrail_logoutput
        }
*/
    }
  }
}

