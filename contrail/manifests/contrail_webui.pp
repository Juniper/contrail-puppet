class __$version__::contrail_webui {

# Following variables need to be set for this resource.
# Those specified with value assiged are optional, if not
# set the assigned value below is used.
#     $contrail_config_ip
#     $contrail_collector_ip
#     $contrail_openstack_ip
#     $contrail_keystone_ip = $contrail_openstack_ip
#     $contrail_cassandra_ip_list
define contrail_webui (
        $contrail_keystone_ip = $contrail_openstack_ip
    ) {
	case $::operatingsystem {
		Ubuntu: {
                      #  notify { "OS is Ubuntu":; }
                      	file {"/etc/init/supervisor-webui.override": ensure => absent, require => Package['contrail-openstack-webui']}
			# Below is temporary to work-around in Ubuntu as Service resource fails
			# as upstart is not correctly linked to /etc/init.d/service-name
			file { '/etc/init.d/supervisor-webui':
			    ensure => link,
			    target => '/lib/init/upstart-job',
			    before => Service["supervisor-webui"]
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

    __$version__::contrail_common::report_status {"webui_started": state => "webui_started"}
    ->
    # Ensure all needed packages are present
    package { 'contrail-openstack-webui' : ensure => present,}

##move this to a seprate resource
#    if 'storage-master' in $contrail_host_roles {
#	package { 'contrail-web-storage' : ensure => present,}
#	-> Service['supervisor-webui']
#    }

    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - contrail-nodemgr, contrail-webui, contrail-setup, supervisor
    # For Centos/Fedora - contrail-api-lib, contrail-webui, contrail-setup, supervisor
    ->

    # Ensure global config js file is present.
    file { "/etc/contrail/config.global.js" : 
        ensure  => present,
        require => Package["contrail-openstack-webui"],
        content => template("$module_name/config.global.js.erb"),
    }
    ->
    # Ensure the services needed are running. The individual services are left
    # under control of supervisor. Hence puppet only checks for continued operation
    # of supervisor-webui service, which in turn monitors status of individual
    # services needed for webui role.
    service { "supervisor-webui" :
        enable => true,
        subscribe => File['/etc/contrail/config.global.js'],
        ensure => running,
    }
    ->
    __$version__::contrail_common::report_status {"webui_completed": state => "webui_completed"}

}
# end of user defined type contrail_webui.

}
