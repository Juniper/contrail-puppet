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
# [*collector_ip*]
#     Control interface IP address of the server running collector module
#
# [*database_ip_list*]
#     List of control interface IP addresses of all servers running cassandra service.
#
# [*control_ip_list*]
#     List of control interface IP addresses of all servers running contrail control node.
#
# [*openstack_ip*]
#     IP address of openstack controller node.
#
# [*uuid*]
#     uuid number
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
# [*use_certs*]
#     Flag to indicate if certificates to be used for authentication.
#     (Optional) - Defaults to false
#
# [*multi_tenancy*]
#     Flag to indicate if multi tenancy is used for openstack.
#     (optional) - Defaults to true.
#
# [*zookeeper_ip_list*]
#     List of control interface IP addresses of all servers running zookeeper services.
#     (optional) - Defaults to database_ip_list
#
# [*quantum_port*]
#     Quantum port number
#     (optional) - Defaults to "9697"
#
# [*quantum_service_protocol*]
#     Quantum Service protocol value (http or https)
#     (optional) - Defaults to "http".
#
# [*keystone_auth_protocol*]
#     Keystone authentication protocol.
#     (Optional) - Defaults to "http".
#
# [*keystone_auth_port*]
#     Keystone authentication port.
#     (Optional) - Defaults to 35357
#
# [*keystone_service_tenant*]
#     Keystone service tenant name.
#     (optional) - Defaults to "service".
#
# [*keystone_insecure_flag*]
#     Flag for Keystone secure/insecure
#     (Optional) - Defaults to false
#
# [*api_nworkers*]
#     Number of threads in config API service. This value is also used for number
#     of discovery service threads
#     (Optional) - Defaults to 1.
#
# [*haproxy*]
#     If HAproxy is configured and enabled. Even if this is passed as true (enabled), if
#     contrail_internal_vip is defined, haproxy = false is used.
#     (Optional) - Defaults to false.
#
# [*keystone_region_name*]
#     Keystone region name.
#     (optional) - Defaults to "RegionOne".
#
# [*manage_neutron*]
#     Flag to indicate if configuring neutron user/role in keystone is required.
#     (optional) - Defaults to true
#
# [*openstack_manage_amqp*]
#     flag to indicate if amqp service is managed by openstack node or contrail
#     config node. amqp_server_ip is set based on value of this flag. If false,
#     use contrail_internal_vip or config_ip. If true, use internal_vip or
#     openstack_ip. Note : If amqp_server_ip is specifically provided (next param)
#     that value is used regardless of value of manage_amqp flag.
#     (optional) - Defaults to false, meaning contrail config to manage amqp.
#
# [*amqp_server_ip*]
#     If Rabbitmq is running on a different server, specify its IP address here.
#     (optional) - Defaults to "".
#
# [*openstack_mgmt_ip*]
#     Management interface address of openstack node (if management and control are separate
#     interfaces on that node)
#     (optional) - Defaults to "", meaning use openstack_ip.
#
# [*internal_vip*]
#     Virtual mgmt IP address for openstack modules
#     (optional) - Defaults to ""
#
# [*external_vip*]
#     Virtual control/data IP address for openstack modules
#     (optional) - Defaults to ""
#
# [*contrail_internal_vip*]
#     Virtual mgmt IP address for contrail modules
#     (optional) - Defaults to "", in which case value of internal_vip is used.
#
# [*config_ip_list*]
#     List of control interface IPs of all the servers running config role.
#     (optional) - Defaults to single node (list with host_control_ip)
#     This is used to derive following variables used by this module.
#     - amqp_server_ip : set to contrail_internal_vip or internal_vip or
#       ip address of first config node.
#
# [*config_name_list*]
#     List of hostnames of all servers running config role.
#     (optional) - Defaults to list with current node hostname alone.
#
# [*database_ip_port*]
#     Database IP port number
#     (optional) - Defaults to "9160"
#
# [*zk_ip_port*]
#     Zookeeper IP port number
#     (optional) - Defaults to "2181"
#
# [*hc_interval*]
#     contrail HC interval used by contrail components to send heart beat
#     to discovery service.
#     (Optional) - Defaults to 5 seconds.
#
# [*vmware_ip*]
#     VMware IP address (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*vmware_username*]
#     VMware user name (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*vmware_password*]
#     vmware_password (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*vmware_vswitch*]
#     VMware vswitch value (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::uninstall_config (
    $host_control_ip = $::contrail::params::host_ip,
    $collector_ip = $::contrail::params::collector_ip_list[0],
    $database_ip_list = $::contrail::params::database_ip_list,
    $control_ip_list = $::contrail::params::control_ip_list,
    $openstack_ip = $::contrail::params::openstack_ip_list[0],
    $uuid = $::contrail::params::uuid,
    $keystone_ip = $::contrail::params::keystone_ip,
    $keystone_admin_token = $::contrail::params::keystone_admin_token,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $keystone_service_token = $::contrail::params::keystone_service_token,
    $use_certs = $::contrail::params::use_certs,
    $multi_tenancy = $::contrail::params::multi_tenancy,
    $zookeeper_ip_list = $::contrail::params::zk_ip_list_to_use,
    $quantum_port = $::contrail::params::quantum_port,
    $quantum_service_protocol = $::contrail::params::quantum_service_protocol,
    $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol,
    $keystone_auth_port = $::contrail::params::keystone_auth_port,
    $keystone_service_tenant = $::contrail::params::keystone_service_tenant,
    $keystone_insecure_flag = $::contrail::params::keystone_insecure_flag,
    $api_nworkers = $::contrail::params::api_nworkers,
    $haproxy = $::contrail::params::haproxy,
    $keystone_region_name = $::contrail::params::keystone_region_name,
    $manage_neutron = $::contrail::params::manage_neutron,
    $openstack_manage_amqp = $::contrail::params::openstack_manage_amqp,
    $amqp_server_ip = $::contrail::params::amqp_server_ip,
    $openstack_mgmt_ip = $::contrail::params::openstack_mgmt_ip_list_to_use[0],
    $internal_vip = $::contrail::params::internal_vip,
    $external_vip = $::contrail::params::external_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $contrail_plugin_location = $::contrail::params::contrail_plugin_location,
    $config_ip_list = $::contrail::params::config_ip_list,
    $config_name_list = $::contrail::params::config_name_list,
    $database_ip_port = $::contrail::params::database_ip_port,
    $zk_ip_port = $::contrail::params::zk_ip_port,
    $hc_interval = $::contrail::params::hc_interval,
    $vmware_ip = $::contrail::params::vmware_ip,
    $vmware_username = $::contrail::params::vmware_username,
    $vmware_password = $::contrail::params::vmware_password,
    $vmware_vswitch = $::contrail::params::vmware_vswitch,
    $config_ip = $::contrail::params::config_ip_to_use,
    $collector_ip = $::contrail::params::collector_ip_to_use,
    $vip = $::contrail::params::vip_to_use,
    $contrail_rabbit_port= $::contrail::params::contrail_rabbit_port,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) inherits ::contrail::params {

    # Main code for class starts here
    if $use_certs == true {
	$ifmap_server_port = '8444'
    }
    else {
	$ifmap_server_port = '8443'
    }

    notify { "uninstall is $::contrail::profile::config::uninstall":; }
    $uninstall_config = $::contrail::profile::config::uninstall
    $analytics_api_port = '8081'
    $contrail_plugin_file = '/etc/neutron/plugins/opencontrail/ContrailPlugin.ini'
    # Set keystone IP to be used.
    if ($keystone_ip != "") {
        $keystone_ip_to_use = $keystone_ip
    }
    elsif ($internal_vip != "") {
        $keystone_ip_to_use = $internal_vip
    }
    else {
        $keystone_ip_to_use = $openstack_ip
    }

    if $multi_tenancy == true {
	$memcached_opt = "memcache_servers=127.0.0.1:11211"
    }
    else {
	$memcached_opt = ""
    }
    # Initialize the multi tenancy option will update latter based on vns argument
    if ($multi_tenancy == true) {
	$mt_options = "admin,$keystone_admin_password,$keystone_admin_tenant"
    } else {
	$mt_options = "None"
    }

    if ($multi_tenancy == true) {
	$multi_options = "--admin_user admin --admin_password $keystone_admin_password --admin_tenant_name $keystone_admin_tenant"
    } else {
	$multi_options = ""
    }

    $provision_opp = "delete"



    # Supervisor contrail-api.ini
    $api_port_base = '910'
    # Supervisor contrail-discovery.ini
    $disc_port_base = '911'
    $disc_nworkers = $api_nworkers

    # Set amqp_server_ip
    if ($amqp_sever_ip != "") {
        $amqp_server_ip_to_use = $amqp_sever_ip
    }
    elsif ($openstack_manage_amqp) {
        if ($internal_vip != "") {
            $amqp_server_ip_to_use = $internal_vip
        }
        else {
            $amqp_server_ip_to_use = $openstack_ip
        }
    }
    else {
        if ($contrail_internal_vip != "") {
            $amqp_server_ip_to_use = $contrail_internal_vip
        }
        elsif ($internal_vip != "") {
            $amqp_server_ip_to_use = $internal_vip
        }
        else {
            $amqp_server_ip_to_use = $config_ip
        }
    }

    # Set number of config nodes
    $cfgm_number = size($config_ip_list)
    if ($cfgm_number == 1) {
        $rabbitmq_conf_template = "rabbitmq_config_single_node.erb"
    }
    else {
        $rabbitmq_conf_template = "rabbitmq_config.erb"
    }

    if ( $host_control_ip == $config_ip_list[0]) {

        $master = "yes"		
    } else {
        $master = "no"
    }


    $cfgm_ip_list_shell = inline_template('<%= @config_ip_list.map{ |ip| "#{ip}" }.join(",") %>')
    $cfgm_name_list_shell = inline_template('<%= @config_name_list.map{ |ip| "#{ip}" }.join(",") %>')
    $rabbit_env = "NODE_IP_ADDRESS=${host_control_ip}\nNODENAME=rabbit@${hostname}ctl\n"

    case $::operatingsystem {
	Ubuntu: {
	    file {"/etc/init/supervisor-config.override": ensure => absent, require => Package['contrail-openstack-config']}
	    file {"/etc/init/neutron-server.override": ensure => absent, require => Package['contrail-openstack-config']}

	    file { "/etc/contrail/supervisord_config_files/contrail-api.ini" :
		ensure  => absent,
		require => Package["contrail-openstack-config"],
		content => template("$module_name/contrail-api.ini.erb"),
	    }

	    file { "/etc/contrail/supervisord_config_files/contrail-discovery.ini" :
		ensure  => absent,
		require => Package["contrail-openstack-config"],
		content => template("$module_name/contrail-discovery.ini.erb"),
	    }

    # Below is temporary to work-around in Ubuntu as Service resource fails
    # as upstart is not correctly linked to /etc/init.d/service-name
	    file { '/etc/init.d/supervisor-config':
		ensure => link,
		target => '/lib/init/upstart-job',
		before => Service["supervisor-config"]
	    }


	}
	Centos: {
		       # notify { "OS is Ubuntu":; }
	    file { "/etc/contrail/supervisord_config_files/contrail-api.ini" :
		ensure  => absent,
		require => Package["contrail-openstack-config"],
		content => template("$module_name/contrail-api-centos.ini.erb"),
	    }

	    file { "/etc/contrail/supervisord_config_files/contrail-discovery.ini" :
		ensure  => absent,
		require => Package["contrail-openstack-config"],
		content => template("$module_name/contrail-discovery-centos.ini.erb"),
	    }

	}
	Fedora: {
		    #        notify { "OS is Ubuntu":; }
	    file { "/etc/contrail/supervisord_config_files/contrail-api.ini" :
		ensure  => absent,
		require => Package["contrail-openstack-config"],
		content => template("$module_name/contrail-api-centos.ini.erb"),
	    }

	    file { "/etc/contrail/supervisord_config_files/contrail-discovery.ini" :
		ensure  => absent,
		require => Package["contrail-openstack-config"],
		content => template("$module_name/contrail-discovery-centos.ini.erb"),
	    }

	}
	default: {
	    # notify { "OS is $operatingsystem":; }
	}
    }
    if ( $uninstall_config == true ) {
      $pkg_state = "purged"
#      $pkg_options = ["--purge", "--auto-remove"]
      $uninstall_options = ["--auto-remove"]
      $pkg_options = []
      $notify_options = ["Exec[apt_auto_remove]"]
    } else {
      $pkg_state = "latest"
      $pkg_options = []
      $notify_options = ["Service[supervisor-config]"]
      $uninstall_options = []
    }
    contrail::lib::report_status { "uninstall_config_started":
        state => "uninstall_config_started", 
        contrail_logoutput => $contrail_logoutput }
    ->
    exec { "provision-role-config" :
	command => "python /usr/share/contrail-utils/provision_config_node.py --api_server_ip $config_ip_to_use --host_name $hostname --host_ip $host_control_ip  --oper $provision_opp $multi_options && echo provision-role-config-$provision_opp >> /etc/contrail/contrail_config_exec.out",
#	require => [ ],
	provider => shell,
	logoutput => $contrail_logoutput
    }


    service { "supervisor-config" :
	enable => false,
	ensure => stopped,
    }
    ->
    # Ensure all needed packages are absent
    package { 'contrail-openstack-config' : ensure => $pkg_state, install_options => $pkg_options, uninstall_options => $uninstall_options , notify => $notify_options}
    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - supervisor, contrail-nodemgr, contrail-lib, contrail-config, neutron-plugin-contrail, neutron-server, python-novaclient,
    #                     python-keystoneclient, contrail-setup, haproxy, euca2ools, rabbitmq-server, python-qpid, python-iniparse, python-bottle,
    #                     zookeeper, ifmap-server, ifmap-python-client, contrail-config-openstack
    # For Centos/Fedora - contrail-api-lib contrail-api-extension, contrail-config, openstack-quantum-contrail, python-novaclient, python-keystoneclient >= 0.2.0,
    #                     python-psutil, mysql-server, contrail-setup, python-zope-interface, python-importlib, euca2ools, m2crypto, openstack-nova,
    #                     java-1.7.0-openjdk, haproxy, rabbitmq-server, python-bottle, contrail-nodemgr
    # Ensure ctrl-details file is absent with right content.
    ->
    exec { "apt_auto_remove":
	command => "apt-get autoremove -y --purge",
	provider => shell,
	logoutput => $contrail_logoutput
    }
    ->

    #form the sudoers
    file { "/etc/sudoers.d/contrail_sudoers" :
        ensure  => absent,
    }
    ->
    # Ensure log4j.properties file is absent with right content.
    file { "/etc/ifmap-server/log4j.properties" :
	ensure  => absent,
    }
    ->
    # Ensure authorization.properties file is absent with right content.
    file { "/etc/ifmap-server/authorization.properties" :
	ensure  => absent,
    }
    ->
    # Ensure basicauthusers.proprties file is absent with right content.
    file { "/etc/ifmap-server/basicauthusers.properties" :
	ensure  => absent,
    }
    ->
    # Ensure publisher.properties file is absent with right content.
    file { "/etc/ifmap-server/publisher.properties" :
	ensure  => absent,
    }
    ->
    # Ensure all config files with correct content are absent.
    file { "/etc/contrail/contrail-api.conf" :
	ensure  => absent,
    }
    ->
    file { "/etc/contrail/contrail-config-nodemgr.conf" :
        ensure  => absent,
    }
    ->
    file { "/etc/contrail/contrail-keystone-auth.conf" :
	ensure  => absent,
    }
    ->
    file { "/etc/contrail/contrail-schema.conf" :
	ensure  => absent,
    }
    ->
    file { "/etc/contrail/contrail-svc-monitor.conf" :
	ensure  => absent,
    }
    ->
    file { "/etc/contrail/contrail-device-manager.conf" :
	ensure  => absent,
    }
    ->
    file { "/etc/contrail/contrail-discovery.conf" :
	ensure  => absent,
    }
    ->
    file { "/etc/contrail/vnc_api_lib.ini" :
	ensure  => absent,
    }
    ->
    file { "/etc/contrail/contrail_plugin.ini" :
	ensure  => absent,
    }
    ->
    # initd script wrapper for contrail-api
    file { "/etc/init.d/contrail-api" :
	ensure  => absent,
    }
    ->
    # initd script wrapper for contrail-discovery
    file { "/etc/init.d/contrail-discovery" :
	ensure  => absent,
    }
    ->
    # Handle rabbitmq.config changes
    file {"/var/lib/rabbitmq/.erlang.cookie":
	ensure  => absent,
    }->
    file { "/etc/rabbitmq/rabbitmq.config" :
        ensure  => absent,
    }
    ->
    file { "/etc/rabbitmq/rabbitmq-env.conf" :
	ensure  => absent,
    }
    ->
    file { "/etc/contrail/add_etc_host.py" :
	ensure  => absent,
    }
    ->
    file { "/etc/contrail/form_rmq_cluster.sh" :
	ensure  => absent,
	mode => 0755,
#	user => root,
	group => root,
	source => "puppet:///modules/$module_name/form_rmq_cluster.sh"
    }
   
    ->
    contrail::lib::report_status { "uninstall_config_completed":
        state => "config_completed", 
        contrail_logoutput => $contrail_logoutput }

# end of user defined type contrail_config.

}
