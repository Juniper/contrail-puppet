#TODO: Document the class
define contrail::lib::contrail_install_repo(
  $contrail_logoutput = false,
) {
    if ($::lsbdistrelease == '16.04') {
        $package_list = ['contrail-setup', 'python-paramiko' ]
    } else {
        $package_list = ['contrail-fabric-utils', 'contrail-setup' ]
    }

    package { $package_list :
        ensure => latest
    }
    case $::operatingsystem {
        Ubuntu: {
            $install_command = "pip install /opt/contrail/python_packages/Fabric-1.7.5.tar.gz && echo exec-pip-install-fabric >> /etc/contrail/contrail_common_exec.out"
            exec { "exec-pip-install-fabric" :
                command => $install_command,
                provider => shell,
                unless => "grep -qx exec-pip-install-fabric /etc/contrail/contrail_common_exec.out",
                logoutput => $contrail_logoutput
            } ->
            exec { "exec-disable-jre-prompts" :
                command => "echo 'sun-java6-plugin shared/accepted-sun-dlj-v1-1 boolean true' | /usr/bin/debconf-set-selections; echo 'sun-java6-bin shared/accepted-sun-dlj-v1-1 boolean true' | /usr/bin/debconf-set-selections; echo 'sun-java6-jre shared/accepted-sun-dlj-v1-1 boolean true' | /usr/bin/debconf-set-selections; echo 'debconf shared/accepted-oracle-license-v1-1 select true' | sudo debconf-set-selections; echo 'debconf shared/accepted-oracle-license-v1-1 seen true' | sudo debconf-set-selections",
                provider => shell,
                logoutput => $contrail_logoutput
            }
        }
        'Centos', 'Fedora' : {
            package { ['python-Fabric'] :
                ensure => latest
            }
        }
        default: {
        }
    }
    #Untill we upgrade to latest puppet , commenting this out
    #package {Fabric: ensure => present, provider => pip, install_options => ['--find-links=file://opt/contrail/python_packages']}
    # May need to install fabric-utils here. below commented out code is kept for reference, in case needed.
    # pip install --upgrade --no-deps --index-url='' /opt/contrail/python_packages/Fabric-*.tar.gz

    # disabled sun-java-jre and sun-java-bin prompt during installation, add oracle license acceptance in debconf
    # disable prompts during java installation and oracle license acceptance
}
