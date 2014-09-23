class __$version__::contrail_control {

define control-template-scripts {
    # Ensure template param file is present with right content.
    file { "/etc/contrail/${title}" : 
        ensure  => present,
        require => Package["contrail-openstack-control"],
        content => template("$module_name/${title}.erb"),
    }
}

define link-upstarts($contrail_os) {
    # Below is temporary to work-around in Ubuntu as Service resource fails
    # as upstart is not correctly linked to /etc/init.d/service-name
    if ($operatingsystem == "Ubuntu") {
        file { '/etc/init.d/supervisor-control':
            ensure => link,
            target => '/lib/init/upstart-job',
            before => Service["supervisor-control"]
        }
        file { '/etc/init.d/supervisor-dns':
            ensure => link,
            target => '/lib/init/upstart-job',
            before => Service["supervisor-dns"]
        }
        file { '/etc/init.d/contrail-named':
            ensure => link,
            target => '/lib/init/upstart-job',
            before => Service["contrail-named"]
        }
    }



}

# Following variables need to be set for this resource.
#     $contrail_control_ip
#     $contrail_config_ip
#     $contrail_config_port
#     $contrail_config_user
#     $contrail_config_passwd
#     $contrail_collector_ip
#     $contrail_collector_port
#     $contrail_discovery_ip
#     $hostname
#     $host_ip
#     $bgp_port
#     $cert_ops
#     $log_file
#     $contrail_log_file
#     $contrail_api_nworkers
define contrail_control (
    ) {
	case $::operatingsystem {
		Ubuntu: {
                      #  notify { "OS is Ubuntu":; }
		        file { ['/etc/init/supervisor-control.override',
                		'/etc/init/supervisor-dns.override'] :
			        ensure => absent,
				require =>Package['contrail-openstack-control']
	        	}
			#TODO, Is this really needed?
		        service { "supervisor-dns" :
		            enable => true,
		            require => [ Package['contrail-openstack-control']
	                         ],
		            subscribe => File['/etc/contrail/dns.conf'],
		            ensure => running,
		        }
    			# Below is temporary to work-around in Ubuntu as Service resource fails
    			# as upstart is not correctly linked to /etc/init.d/service-name
			file { '/etc/init.d/supervisor-control':
				ensure => link,
				target => '/lib/init/upstart-job',
				before => Service["supervisor-control"]
			}
			file { '/etc/init.d/supervisor-dns':
				ensure => link,
				target => '/lib/init/upstart-job',
				before => Service["supervisor-dns"]
			}
			file { '/etc/init.d/contrail-named':
				ensure => link,
				       target => '/lib/init/upstart-job',
				       before => Service["contrail-named"]
			}

		}
		Centos: {
                       # notify { "OS is Ubuntu":; }

		}
		Fedora: {
                #        notify { "OS is Ubuntu":; }
		}
		default: {
                 #       notify { "OS is $operatingsystem":; }

		}
	}

    __$version__::contrail_common::report_status {"control_started": state => "control_started"}
    ->
    # Ensure all needed packages are present
    package { 'contrail-openstack-control' : ensure => present,}
    ->
    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - supervisor, contrail-api-lib, contrail-control, contrail-dns,
    #                      contrail-setup, contrail-nodemgr
    # For Centos/Fedora - contrail-api-lib, contrail-control, contrail-setup, contrail-libs
    #                     contrail-dns, supervisor


    # Ensure all config files with correct content are present.
    control-template-scripts { ["dns.conf", "contrail-control.conf"]: }

    # Hard-coded to be taken as parameter of vnsi and multi-tenancy options need to be passed to contrail_control too.
    # The below script can be avoided. Sets up puppet agent and waits to get certificate from puppet master.
    # also has service restarts for puppet agent and supervisor-control. Abhay
    ->
    file { "/opt/contrail/contrail_installer/contrail_setup_utils/control-server-setup.sh":
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
    }
    ->
    exec { "control-server-setup" :
        command => "/opt/contrail/contrail_installer/contrail_setup_utils/control-server-setup.sh; echo control-server-setup >> /etc/contrail/contrail_control_exec.out",
        require => File["/opt/contrail/contrail_installer/contrail_setup_utils/control-server-setup.sh"],
        unless  => "grep -qx control-server-setup /etc/contrail/contrail_control_exec.out",
        provider => shell,
        logoutput => "true"
    }
    ->
    # update rndc conf
    exec { "update-rndc-conf-file" :
        command => "sudo sed -i 's/secret \"secret123\"/secret \"xvysmOR8lnUQRBcunkC6vg==\"/g' /etc/contrail/dns/rndc.conf && echo update-rndc-conf-file >> /etc/contrail/contrail_control_exec.out",
        require =>  package["contrail-openstack-control"],
        onlyif => "test -f /etc/contrail/dns/rndc.conf",
        unless  => "grep -qx update-rndc-conf-file /etc/contrail/contrail_control_exec.out",
        provider => shell,
        logoutput => 'true'
    }
    # Ensure the services needed are running.
    ->
    service { "supervisor-control" :
        enable => true,
        require => [ Package['contrail-openstack-control'],
                      ],
        subscribe => File['/etc/contrail/contrail-control.conf'],
        ensure => running,
    }
    #->
    service { "contrail-named" :
        enable => true,
        require => [ Package['contrail-openstack-control']
                     ],
        subscribe => File['/etc/contrail/dns.conf'],
        ensure => running,
    }
    #->
    __$version__::contrail_common::report_status {"control_completed": state => "control_completed"}

}
# end of user defined type contrail_control.

}
