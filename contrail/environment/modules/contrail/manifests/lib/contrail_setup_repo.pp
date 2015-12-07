## TODO: Add documentation
define contrail::lib::contrail_setup_repo(
    $contrail_repo_ip,
    $contrail_logoutput = false,
) {
    $contrail_repo_name = $name
    if ($operatingsystem == "Centos" or $operatingsystem == "Fedora") {
        file { "/etc/yum.repos.d/cobbler-config.repo" :
            ensure  => present,
            content => template("contrail-common/contrail-yum-repo.erb")
        }
    }
    if ($operatingsystem == "Ubuntu") {
        apt::source { "contrail_${contrail_repo_name}":
          location => "http://$contrail_repo_ip/contrail/repo/${contrail_repo_name}",
          repos    => 'main',
          release  => 'contrail',
       }
    }
}
