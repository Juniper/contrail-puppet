## TODO: Add documentation
define contrail::lib::contrail_setup_repo(
    $contrail_repo_ip,
    $contrail_logoutput = false,
) {
    $contrail_repo_name = $name
    if ($operatingsystem == "Centos" or $operatingsystem == "Fedora") {
        file { "/etc/yum.repos.d/cobbler-config.repo" :
            ensure  => present,
            content => template("${module_name}/contrail-yum-repo.erb")
        } ->
        # add check_obsoletes flag off, for bug #1649596
        exec { "/etc/yum/pluginconf.d/priorities.conf":
            command => "echo 'check_obsoletes=1' >> /etc/yum/pluginconf.d/priorities.conf && echo exec-yum-priorities-fix >> /etc/contrail/exec-yum-pririties-fix.out",
            provider => shell,
            unless => "grep -qx exec-yum-priorities-fix /etc/contrail/exec-yum-pririties-fix.out",
            logoutput => true
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
