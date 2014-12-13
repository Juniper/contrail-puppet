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
    if ($operatingsystem == "Ubuntu") {
         $service_provider = upstart
    } else {
         $service_provider = init
    }


    __$version__::contrail_common::report_status {"webui_started": state => "webui_started"}
    ->
    # Ensure all needed packages are present
    package { 'contrail-openstack-webui' : ensure => present,}

    if $contrail_storage_enabled  == '1' {
	package { 'contrail-web-storage' : ensure => present,}
	-> 
	file { "storage.config.global.js":
		path => "/usr/src/contrail/contrail-web-storage/webroot/common/config/storage.config.global.js",
		ensure => present,
        	require => Package["contrail-web-storage"],
        	content => template("$module_name/storage.config.global.js.erb"),
    	}
	-> Service['supervisor-webui']
    } else {
	package { 'contrail-web-storage' : ensure => absent,}
	-> 
	file { "storage.config.global.js":
		path => "/usr/src/contrail/contrail-web-storage/webroot/common/config/storage.config.global.js",
		ensure => absent,
        	content => template("$module_name/storage.config.global.js.erb"),
    	}
	-> Service['supervisor-webui']
    }
    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - contrail-nodemgr, contrail-webui, contrail-setup, supervisor
    # For Centos/Fedora - contrail-api-lib, contrail-webui, contrail-setup, supervisor

    if ($operatingsystem == "Ubuntu"){
        file {"/etc/init/supervisor-webui.override": ensure => absent, require => Package['contrail-openstack-webui']}
    }

    # Ensure global config js file is present.
    file { "/etc/contrail/config.global.js" : 
        ensure  => present,
        require => Package["contrail-openstack-webui"],
        content => template("$module_name/config.global.js.erb"),
    }

    # Below is temporary to work-around in Ubuntu as Service resource fails
    # as upstart is not correctly linked to /etc/init.d/service-name

    # Ensure the services needed are running. The individual services are left
    # under control of supervisor. Hence puppet only checks for continued operation
    # of supervisor-webui service, which in turn monitors status of individual
    # services needed for webui role.
    service { "supervisor-webui" :
        enable => true,
        subscribe => [File['/etc/contrail/config.global.js'], File['storage.config.global.js']],
        provider => $service_provider,
        ensure => running,
    }
    ->
    __$version__::contrail_common::report_status {"webui_completed": state => "webui_completed"}

}
# end of user defined type contrail_webui.

}
