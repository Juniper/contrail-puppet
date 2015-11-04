# This class is used to configure software and services required
# to run config module of contrail software suit.
#
# === Parameters:
#
# [*host_control_ip*]
#     IP address of the server.
#     If server has separate interfaces for management and control, this
#     parameter should provide control interface IP address.
#
# [*keystone_ip*]
#     Key stone IP address, if keystone service is running on a node other
#     than openstack controller.
#     (optional) - Default "", meaning use internal_vip if defined, else use
#     same address as first openstack controller.
#
# [*keystone_admin_token*]
#     Keystone admin token. Admin token value from /etc/keystone/keystone.conf file of
#     keystone/openstack node.
#     (optional) - Defaults to "c0ntrail123"
#
# [*keystone_admin_user*]
#     Keystone admin user name.
#     (optional) - Defaults to "admin".
#
# [*keystone_admin_password*]
#     Keystone admin password.
#     (optional) - Defaults to "contrail123".
#
# [*keystone_admin_tenant*]
#     Keystone admin tenant name.
#     (optional) - Defaults to "admin".
#
# [*keystone_service_token*]
#     Keystone service token.
#     (optional) - Defaults to "c0ntrail123".
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::uninstall_config (
    $host_control_ip = $::contrail::params::host_ip,
    $keystone_ip = $::contrail::params::keystone_ip,
    $keystone_admin_token = $::contrail::params::keystone_admin_token,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $config_ip = $::contrail::params::config_ip_to_use,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $multi_tenancy_options = $::contrail::params::multi_tenancy_options,
) inherits ::contrail::params {

    # Supervisor contrail-api.ini
    $api_port_base = '910'
    # Supervisor contrail-discovery.ini
    $disc_port_base = '911'
    $disc_nworkers = $api_nworkers

    case $::operatingsystem {
	Ubuntu: {
	    file {"/etc/init/supervisor-config.override": ensure => absent, require => Package['contrail-openstack-config']}
	    file {"/etc/init/neutron-server.override": ensure => absent, require => Package['contrail-openstack-config']}

	    file { "/etc/contrail/supervisord_config_files/contrail-api.ini" :
		ensure  => absent,
	    }

	    file { "/etc/contrail/supervisord_config_files/contrail-discovery.ini" :
		ensure  => absent,
	    }

    # Below is temporary to work-around in Ubuntu as Service resource fails
    # as upstart is not correctly linked to /etc/init.d/service-name
	    file { '/etc/init.d/supervisor-config':
		ensure => link,
		target => '/lib/init/upstart-job',
	    }


	}
	Centos: {
		       # notify { "OS is Ubuntu":; }
	    file { "/etc/contrail/supervisord_config_files/contrail-api.ini" :
		ensure  => absent,
	    }

	    file { "/etc/contrail/supervisord_config_files/contrail-discovery.ini" :
		ensure  => absent,
	    }

	}
	Fedora: {
		    #        notify { "OS is Ubuntu":; }
	    file { "/etc/contrail/supervisord_config_files/contrail-api.ini" :
		ensure  => absent,
	    }

	    file { "/etc/contrail/supervisord_config_files/contrail-discovery.ini" :
		ensure  => absent,
	    }

	}
	default: {
	    # notify { "OS is $operatingsystem":; }
	}
    }
    contrail::lib::report_status { "uninstall_config_started":
        state => "uninstall_config_started", 
        contrail_logoutput => $contrail_logoutput }
    ->
    exec { "provision-role-config" :
	command => "python /usr/share/contrail-utils/provision_config_node.py --api_server_ip $config_ip_to_use --host_name $hostname --host_ip $host_control_ip  --oper del $multi_tenancy_options && echo provision-role-config-del >> /etc/contrail/contrail_config_exec.out",
#	require => [ ],
	provider => shell,
	logoutput => $contrail_logoutput
    }
    ->
    service { "supervisor-config" :
	enable => false,
	ensure => stopped,
    }
    ->
    # Ensure all needed packages are absent
    package { 'contrail-openstack-config' : ensure => purged, install_options => [], uninstall_options => ["--auto-remove"] , notify => ["Exec[apt_auto_remove_config]"]}
    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - supervisor, contrail-nodemgr, contrail-lib, contrail-config, neutron-plugin-contrail, neutron-server, python-novaclient,
    #                     python-keystoneclient, contrail-setup, haproxy, euca2ools, rabbitmq-server, python-qpid, python-iniparse, python-bottle,
    #                     zookeeper, ifmap-server, ifmap-python-client, contrail-config-openstack
    # For Centos/Fedora - contrail-api-lib contrail-api-extension, contrail-config, openstack-quantum-contrail, python-novaclient, python-keystoneclient >= 0.2.0,
    #                     python-psutil, mysql-server, contrail-setup, python-zope-interface, python-importlib, euca2ools, m2crypto, openstack-nova,
    #                     java-1.7.0-openjdk, haproxy, rabbitmq-server, python-bottle, contrail-nodemgr
    # Ensure ctrl-details file is absent with right content.
    #TODO Convert this into a resource
    exec { "apt_auto_remove_config":
	command => "apt-get autoremove -y --purge",
	provider => shell,
	logoutput => $contrail_logoutput
    }
    ->
    file { [           
            '/etc/sudoers.d/contrail_sudoers',
            '/etc/ifmap-server/log4j.properties',
            '/etc/ifmap-server/authorization.properties',
            '/etc/ifmap-server/basicauthusers.properties',
            '/etc/ifmap-server/publisher.properties',
            '/etc/contrail/contrail-api.conf',
            '/etc/contrail/contrail-config-nodemgr.conf',
            '/etc/contrail/contrail-keystone-auth.conf',
            '/etc/contrail/contrail-schema.conf',
            '/etc/contrail/contrail-svc-monitor.conf',
            '/etc/contrail/contrail-device-manager.conf',
            '/etc/contrail/contrail-discovery.conf',
            '/etc/contrail/vnc_api_lib.ini',
            '/etc/contrail/contrail_plugin.ini',
            '/etc/init.d/contrail-api',
            '/etc/init.d/contrail-discovery',
            '/etc/rabbitmq/rabbitmq.config',
            '/etc/rabbitmq/rabbitmq-env.conf',
            '/etc/contrail/add_etc_host.py',
            '/etc/contrail/form_rmq_cluster.sh',
            '/var/lib/rabbitmq/.erlang.cookie'
           ]:
        ensure  => absent,
    }
    ->
    contrail::lib::report_status { "uninstall_config_completed":
        state => "config_completed", 
        contrail_logoutput => $contrail_logoutput }

# end of user defined type contrail_config.

}
