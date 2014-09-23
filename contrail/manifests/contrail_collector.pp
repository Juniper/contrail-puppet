class __$version__::contrail_collector {

define collector-template-scripts {
    # Ensure template param file is present with right content.
    file { "/etc/contrail/${title}" : 
        ensure  => present,
        require => Package["contrail-openstack-analytics"],
        content => template("$module_name/${title}.erb"),
    }
}

# Following variables need to be set for this resource.
#     $contrail_config_ip
#     $contrail_collector_ip
#     $contrail_redis_master_ip
#     $contrail_redis_role
#     $contrail_cassandra_ip_list
#     $contrail_cassandra_ip_port
#     $contrail_num_collector_nodes
#     $contrail_analytics_data_ttl
define contrail_collector (
    ) {
	case $::operatingsystem {
		Ubuntu: {
                      #  notify { "OS is Ubuntu":; }
		      file {"/etc/init/supervisor-analytics.override": ensure => absent, require => Package['contrail-openstack-analytics']}
		      file { '/etc/init.d/supervisor-analytics':
		      	     ensure => link,
			     target => '/lib/init/upstart-job',
			     before => Service["supervisor-analytics"]
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
    if($internal_vip != "") {
    	$contrail_analytics_api_port = 9081
    } else {
	$contrail_analytics_api_port = 8081
    }

    __$version__::contrail_common::report_status {"collector_started": state => "collector_started"}
    ->
    # Ensure all needed packages are present
    package { 'contrail-openstack-analytics' : ensure => present,}
    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - supervisor, python-contrail, contrail-analytics, contrail-setup, contrail-nodemgr
    # For Centos/Fedora - contrail-api-pib, contrail-analytics, contrail-setup, contrail-nodemgr
    ->
/*
    if ($operatingsystem == "Ubuntu"){
    }
*/
   
    # Ensure all config files with correct content are present.
    collector-template-scripts { ["contrail-analytics-api.conf" , "contrail-collector.conf", "contrail-query-engine.conf"]: }
    ->
    # The below commented code is not used in latest fab. Need to check with analytics team and then remove
    # if not needed.
    # if ($contrail_num_collector_nodes > 0) {
    #     if ($contrail_num_collector_nodes > 1) {
    #         $sentinel_quoram = $contrail_num_collector_nodes - 1
    #     }
    #     else {
    #         $sentinel_quoram = 1
    #     }
    #     file { "/etc/contrail/sentinel.conf" : 
    #         ensure  => present,
    #         require => Package["contrail-openstack-analytics"],
    #         content => template("$module_name/sentinel.conf.erb"),
    #     }
    #     if ($contrail_redis_role == "slave") {
    #         file { "/etc/contrail/redis-uve.conf" : 
    #             ensure  => present,
    #             require => Package["contrail-openstack-analytics"],
    #             content => template("$module_name/redis-uve.conf.erb"),
    #         }
    #     }
    # }
    # end commented out code.

    # Below is temporary to work-around in Ubuntu as Service resource fails
    # as upstart is not correctly linked to /etc/init.d/service-name
    exec { "redis-conf-exec":
        command => "sed -i -e '/^[ ]*bind/s/^/#/' /etc/redis/redis.conf;chkconfig redis-server on; service redis-server restart && echo redis-conf-exec>> /etc/contrail/contrail-collector-exec.out",
        onlyif => "test -f /etc/redis/redis.conf",
        unless  => "grep -qx redis-conf-exec /etc/contrail/contrail-collector-exec.out",
        provider => shell, 
        logoutput => "true"
    }
    ->
/*
    if ($operatingsystem == "Ubuntu") {
    }
*/

    # Ensure the services needed are running.
    service { "supervisor-analytics" :
        enable => true,
        require => [ Package['contrail-openstack-analytics']
                   ],
        subscribe => [ File['/etc/contrail/contrail-collector.conf'],
                       File['/etc/contrail/contrail-query-engine.conf'],
                       File['/etc/contrail/contrail-analytics-api.conf'] ],
        ensure => running,
    }
    ->
    __$version__::contrail_common::report_status {"collector_completed": state => "collector_completed"}

}
# end of user defined type contrail_collector.

}
