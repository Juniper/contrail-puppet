define contrail::lib::contrail-install-repo(
    $contrail_logoutput = false,
    ) {
    $contrail_repo_type = $name

    if($contrail_repo_type == "contrail-ubuntu-package") {
	$setup_script =  "./setup.sh && echo exec-contrail-setup-$contrail_repo_type-sh >> exec-contrail-setup-sh.out"
	$package_name = "contrail-install-packages"
    } elsif ($contrail_repo_type == "contrail-centos-repo") {
	$setup_script =  "./setup.sh && echo exec-contrail-setup-$contrail_repo_type-sh >> exec-contrail-setup-sh.out"
	$package_name = "contrail-install-packages"
    }


    if ( $package_name != '' ) {
        package {$package_name: ensure => latest, install_options => '--force-yes'}

        exec { "exec-contrail-setup-$contrail_repo_type-sh" :
    	    command => $setup_script,
	    cwd => "/opt/contrail/contrail_packages",
	    require => Package[$package_name],
	    unless  => "grep -qx exec-contrail-setup-$contrail_repo_type-sh /opt/contrail/contrail_packages/exec-contrail-setup-sh.out",
	    provider => shell,
	    logoutput => $contrail_logoutput
        }
    }
}
