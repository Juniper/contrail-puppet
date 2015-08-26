define contrail::lib::contrail-install-repo(
    $contrail_logoutput = false,
    ) {
    $contrail_repo_type = $name

    if (($contrail_repo_type == "contrail-ubuntu-package") or
        ($contrail_repo_type == "contrail-centos-repo")) {
	$package_name = "contrail-install-packages"
    }
    else {
        $package_name = ''
    }

    if ( $package_name != '' ) {
        package {$package_name: ensure => latest, install_options => '--force-yes'} ->

        package { ['binutils', 'make', 'libdpkg-perl', 'patch', 'dpkg-dev',
                   'python-software-properties', 'contrail-fabric-utils', 'contrail-setup' ] :
            ensure => latest
        } ->

        exec { "exec-pip-install-fabric" :
            command => "pip install Fabric --find-links=file://opt/contrail/python_packages && echo exec-pip-install-fabric >> /etc/contrail/contrail_common_exec.out",
            provider => shell,
            unless => "grep -qx exec-pip-install-fabric /etc/contrail/contrail_common_exec.out",
            logoutput => $contrail_logoutput
        }
        #Untill we upgrade to latest puppet , commenting this out
        #package {Fabric: ensure => present, provider => pip, install_options => ['--find-links=file://opt/contrail/python_packages']}
        # May need to install fabric-utils here. below commented out code is kept for reference, in case needed.
        # pip install --upgrade --no-deps --index-url='' /opt/contrail/python_packages/Fabric-*.tar.gz

        # disabled sun-java-jre and sun-java-bin prompt during installation, add oracle license acceptance in debconf
        # disable prompts during java installation and oracle license acceptance
        exec { "exec-disable-jre-prompts" :
    	    command => "echo 'sun-java6-plugin shared/accepted-sun-dlj-v1-1 boolean true' | /usr/bin/debconf-set-selections; echo 'sun-java6-bin shared/accepted-sun-dlj-v1-1 boolean true' | /usr/bin/debconf-set-selections; echo 'sun-java6-jre shared/accepted-sun-dlj-v1-1 boolean true' | /usr/bin/debconf-set-selections; echo 'debconf shared/accepted-oracle-license-v1-1 select true' | sudo debconf-set-selections; echo 'debconf shared/accepted-oracle-license-v1-1 seen true' | sudo debconf-set-selections",
	    provider => shell,
	    logoutput => $contrail_logoutput
        }
    }
}
