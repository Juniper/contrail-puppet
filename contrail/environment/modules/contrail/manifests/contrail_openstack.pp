# == Class: contrail::contrail_openstack
#
# This class is used to configure software and services required
# to perfrom any additional functionality required on openstack node
# by contrail modules (e.g. create openstackrc, keystonerc, ec2rc files etc).
# Any new code needed to be executed on openstack node by contrail should be
# added here.
#
# === Parameters:
#
# [*openstack_ip*]
#     IP address of server running openstack services. If the server has
#     separate interfaces for management and control, this parameter
#     should provide control interface IP address.
#
# [*keystone_ip*]
#     IP address of server running keystone service. Should be specified if
#     keystone is running on a server other than openstack server.
#     (optional) - Defaults to "", meaning use openstack_ip.
#
# [*internal_vip*]
#     Virtual mgmt IP address for openstack modules
#     (optional) - Defaults to ""
#
# [*keystone_admin_user*]
#     Keystone admin user.
#     (optional) - Defaults to "admin".
#
# [*keystone_admin_password*]
#     Keystone admin password.
#     (optional) - Defaults to "contrail123"
#
# [*keystone_admin_tenant*]
#     Keystone admin tenant name.
#     (optional) - Defaults to "admin".
#
# [*keystone_service_token*]
#     openstack service token value.
#     (optional) - Defaults to "contrail123"
#
# [*keystone_auth_protocol*]
#     Keystone authentication protocol.
#     (optional) - Defaults to "http".
#

define openstack-scripts {
    file { "/opt/contrail/bin/${title}.sh":
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
    }
    exec { "setup-${title}" :
        command => "/opt/contrail/bin/${title}.sh $operatingsystem && echo setup-${title} >> /etc/contrail/contrail_openstack_exec.out",
        require => [ File["/opt/contrail/bin/${title}.sh"],
                     File["/etc/contrail/ctrl-details"] ],
        unless  => "grep -qx setup-${title} /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => "true"
    }
}

define setup-keystone-2 {
# repeat keystone setup (workaround for now) Needs to be fixed .. Abhay
    if ($operatingsystem == "Ubuntu") {
        exec { "setup-keystone-server-2setup" :
            command => "/opt/contrail/bin/keystone-server-setup.sh $operatingsystem && echo setup-keystone-server-2setup >> /etc/contrail/contrail_openstack_exec.out",
            require => [ File["/opt/contrail/bin/keystone-server-setup.sh"],
            File["/etc/contrail/ctrl-details"],
            Openstack-scripts['nova-server-setup'] ],
            unless  => "grep -qx setup-keystone-server-2setup /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => "true",
            before => Service['mysqld']
        }
# Below is temporary to work-around in Ubuntu as Service resource fails
# as upstart is not correctly linked to /etc/init.d/service-name
        file { '/etc/init.d/mysqld':
            ensure => link,
            target => '/lib/init/upstart-job',
            before => Service["mysqld"]
        }
        file { '/etc/init.d/openstack-keystone':
            ensure => link,
            target => '/lib/init/upstart-job',
            before => Service["openstack-keystone"]
        }
    }

}

define setup-keystone-service {
    if ($operatingsystem == "Ubuntu") {
        service { "openstack-keystone" :
            enable => true,
            require => [ Package['contrail-openstack'],
            Openstack-scripts["nova-server-setup"] ],
            ensure => running,
        }

    } else {
        service { "keystone" :
            enable => true,
            require => [ Package['contrail-openstack'],
                         Openstack-scripts["nova-server-setup"] ],
            ensure => running,
        }
    }
}


class contrail::contrail_openstack (
    $openstack_ip = $::contrail::params::openstack_ip_list[0],
    $openstack_ip_list = $::contrail::params::openstack_ip_list,
    $host_control_ip = $::contrail::params::host_ip,
    $keystone_ip = $::contrail::params::keystone_ip,
    $internal_vip = $::contrail::params::internal_vip,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $keystone_service_token = $::contrail::params::keystone_service_token,
    $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol
) inherits ::contrail::params
{

    $contrail_vm_ip = ""
    $contrail_vm_username = ""
    $contrail_vm_passwd = ""
    $contrail_vswitch = ""
    $config_ip = $config_ip_list[0]

    $openstack_mgmt_ip = $::contrail::params::openstack_mgmt_ip_list_to_use[0]
    $openstack_manage_amqp = $::contrail::params::openstack_manage_amqp
    $amqp_server_ip = $::contrail::params::amqp_server_ip
#    $internal_vip = $::contrail::params::internal_vip
    $external_vip = $::contrail::params::external_vip
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip
    $openstack_index = inline_template('<%= @openstack_ip_list.index(@host_control_ip) %>') + 1
    notify { "openstack - keystone_ip = $keystone_ip":; }

    if ($keystone_ip != "") {
        $keystone_ip_to_use = $keystone_ip
    }
    elsif ($internal_vip != "") {
        $keystone_ip_to_use = $internal_vip
    }
    else {
        $keystone_ip_to_use = $openstack_ip
    }

    #TODO shoud we use internal_vip here ?

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


    contrail::lib::report_status { "openstack_started": state => "openstack_started" }
    ->
    # list of packages
    package { 'contrail-openstack' : ensure => present,}
    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - python-contrail, openstack-dashboard, contrail-openstack-dashboard, glance, keystone, nova-api, nova-common,
    #                     nova-conductor, nova-console, nova-objectstore, nova-scheduler, cinder-api, cinder-common, cinder-scheduler,
    #                     mysql-server, contrail-setup, memcached, nova-novncproxy, nova-consoleauth, python-m2crypto, haproxy,
    #                     rabbitmq-server, apache2, libapache2-mod-wsgi, python-memcache, python-iniparse, python-qpid, euca2ools
    # For Centos/Fedora - contrail-api-lib, openstack-dashboard, contrail-openstack-dashboard, openstack-glance, openstack-keystone,
    #                     openstack-nova, openstack-cinder, mysql-server, contrail-setup, memcached, openstack-nova-novncproxy,
    #                     python-glance, python-glanceclient, python-importlib, euca2ools, m2crypto, qpid-cpp-server,
    #                     haproxy, rabbitmq-server
    if ($internal_vip != "") {
        exec { "ha-hacks" :

            command => "openstack-config --set /etc/keystone/keystone.conf DEFAULT public_port 6000 && openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_port 35358 && echo ha-hacks >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            unless  => "grep -qx -hacks /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }
    }

    if ($operatingsystem == "Centos" or $operatingsystem == "Fedora") {
        exec { "dashboard-local-settings-1" :
            command => "sed -i 's/ALLOWED_HOSTS =/#ALLOWED_HOSTS =/g' /etc/openstack_dashboard/local_settings && echo dashboard-local-settings-1 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack_dashboard/local_settings",
            unless  => "grep -qx dashboard-local-settings-1 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }
        exec { "dashboard-local-settings-2" :
            command => "sed -i 's/ALLOWED_HOSTS =/#ALLOWED_HOSTS =/g' /etc/openstack-dashboard/local_settings && echo dashboard-local-settings-2 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack-dashboard/local_settings",
            unless  => "grep -qx dashboard-local-settings-2 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }
    }

    if ($operatingsystem == "Ubuntu") {

        $line1="HORIZON_CONFIG[\'customization_module\']=\'contrail_openstack_dashboard.overrides\'"
        exec { "dashboard-local-settings-3" :
            command => "sed -i '/HORIZON_CONFIG.*customization_module.*/d' /etc/openstack-dashboard/local_settings.py && echo \"$line1\"  >> /etc/openstack-dashboard/local_settings.py  && echo dashboard-local-settings-3 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack-dashboard/local_settings.py",
            unless  => "grep -qx dashboard-local-settings-3 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }

        $line2="LOGOUT_URL=\'/horizon/auth/logout/\'"
        exec { "dashboard-local-settings-4" :

            command => "sed -i '/LOGOUT_URL.*/d' /etc/openstack-dashboard/local_settings.py && echo \"$line2\" >> /etc/openstack-dashboard/local_settings.py && service apache2 restart && echo dashboard-local-settings-4 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack-dashboard/local_settings.py",
            unless  => "grep -qx dashboard-local-settings-4 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }
    }
    if ($operatingsystem == "Centos") {
        exec { "dashboard-local-settings-3" :
            command => "echo dashboard-local-settings-3 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack-dashboard/local_settings",
            unless  => "grep -qx dashboard-local-settings-3 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }

        exec { "dashboard-local-settings-4" :
            command => "echo dashboard-local-settings-4 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack-dashboard/local_settings",
            unless  => "grep -qx dashboard-local-settings-4 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }
    }

    exec { "update-nova-conf-file" :
        command => "sed -i 's/rpc_backend = nova.openstack.common.rpc.impl_qpid/#rpc_backend = nova.openstack.common.rpc.impl_qpid/g' /etc/nova/nova.conf && echo update-nova-conf-file >> /etc/contrail/contrail_openstack_exec.out",
        require =>  package["contrail-openstack"],
        onlyif => "test -f /etc/nova/nova.conf",
        unless  => "grep -qx update-nova-conf-file /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => 'true'
    }

/*
    ##Chhandak Added this section to update nova.conf with corect rabit_host ip
    exec { "update-nova-conf-file1" :
        #command => "sed -i 's/#rabbit_host\s*=\s*127.0.0.1/rabbit_host = $contrail_amqp_server_ip/g' /etc/nova/nova.conf && echo update-nova-conf-file1 >> /etc/contrail/contrail_openstack_exec.out",
        command => "openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_host $contrail_amqp_server_ip && echo update-nova-conf-file1 >> /etc/contrail/contrail_openstack_exec.out",
        require =>  package["contrail-openstack"],
        onlyif => "test -f /etc/nova/nova.conf",
        unless  => "grep -qx update-nova-conf-file1 /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => 'true'
    }

    ##Chhandak Added this section to update nova.conf with corect rabit_host ip
    exec { "update-nova-conf-file2" :
        #command => "sudo sed -i 's/#rabbit_host\s*=\s*127.0.0.1/rabbit_host = $contrail_amqp_server_ip/g' /etc/nova/nova.conf && echo update-nova-conf-file1 >> /etc/contrail/contrail_openstack_exec.out",
        command => "openstack-config --set /etc/nova/nova.conf keystone_authtoken rabbit_host $contrail_amqp_server_ip  && echo update-nova-conf-file2 >> /etc/contrail/contrail_openstack_exec.out",
        require =>  package["contrail-openstack"],
        onlyif => "test -f /etc/nova/nova.conf",
        unless  => "grep -qx update-nova-conf-file2 /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => 'true'
    }
*/

    exec { "update-cinder-conf-file" :
        command => "sed -i 's/rpc_backend = cinder.openstack.common.rpc.impl_qpid/#rpc_backend = cinder.openstack.common.rpc.impl_qpid/g' /etc/cinder/cinder.conf && echo update-cinder-conf-file >> /etc/contrail/contrail_openstack_exec.out",
        require =>  package["contrail-openstack"],
        onlyif => "test -f /etc/cinder/cinder.conf",
        unless  => "grep -qx update-cinder-conf-file /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => 'true'
    }

    # Handle rabbitmq.conf changes
    #$conf_file = "/etc/rabbitmq/rabbitmq.config"
    #if ! defined(File["/etc/contrail/contrail_setup_utils/cfg-qpidd-rabbitmq.sh"]) {
    #    file { "/etc/contrail/contrail_setup_utils/cfg-qpidd-rabbitmq.sh" : 
    #        ensure  => present,
    #        mode => 0755,
    #        owner => root,
    #        group => root,
    #        source => "puppet:///modules/$module_name/cfg-qpidd-rabbitmq.sh"
    #    }
    #}
    #if ! defined(Exec["exec-cfg-qpidd-rabbitmq"]) {
    #    exec { "exec-cfg-qpidd-rabbitmq" :
    #        command => "/bin/bash /etc/contrail/contrail_setup_utils/cfg-qpidd-rabbitmq.sh $operatingsystem $conf_file && echo exec-cfg-qpidd-rabbitmq >> /etc/contrail/contrail_openstack_exec.out",
    #        require =>  File["/etc/contrail/contrail_setup_utils/cfg-qpidd-rabbitmq.sh"],
    #        unless  => "grep -qx exec-cfg-qpidd-rabbitmq /etc/contrail/contrail_openstack_exec.out",
    #        provider => shell,
    #        logoutput => 'true'
    #    }
    #}

    file { "/etc/contrail/contrail_setup_utils/api-paste.sh" : 
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
        source => "puppet:///modules/$module_name/api-paste.sh"
    }
    exec { "exec-api-paste" :
        command => "/bin/bash /etc/contrail/contrail_setup_utils/api-paste.sh && echo exec-api-paste >> /etc/contrail/contrail_openstack_exec.out",
        require =>  File["/etc/contrail/contrail_setup_utils/api-paste.sh"],
        unless  => "grep -qx exec-api-paste /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => 'true'
    }

    exec { "exec-openstack-qpid-rabbitmq-hostname" :
        command => "echo \"rabbit_host = $contrail_amqp_server_ip\" >> /etc/nova/nova.conf && echo exec-openstack-qpid-rabbitmq-hostname >> /etc/contrail/contrail_openstack_exec.out",
        require =>  Package["contrail-openstack"],
        unless  => ["grep -qx exec-openstack-qpid-rabbitmq-hostname /etc/contrail/contrail_openstack_exec.out",
                    "grep -qx \"rabbit_host = $contrail_amqp_server_ip\" /etc/nova/nova.conf"],
        provider => shell,
        logoutput => 'true'
    }
    
    # Ensure ctrl-details file is present with right content.
    if ! defined(File["/etc/contrail/ctrl-details"]) {
        $quantum_port = "9697"
        if $contrail_haproxy == "enable" {
		$quantum_ip = "127.0.0.1"
	} else {
		$quantum_ip = $config_ip
	}
        file { "/etc/contrail/ctrl-details" :
            ensure  => present,
            content => template("$module_name/ctrl-details.erb"),
        }

    }

    # Ensure service.token file is present with right content.
    if ! defined(File["/etc/contrail/service.token"]) {
        file { "/etc/contrail/service.token" :
            ensure  => present,
            content => template("$module_name/service.token.erb"),
        }
    }

    if ! defined(Exec["neutron-os-conf-exec"]) {
        exec { "neutron-os-conf-exec":
            command => "sed -i 's/rpc_backend\s*=\s*neutron.openstack.common.rpc.impl_qpid/#rpc_backend = neutron.openstack.common.rpc.impl_qpid/g' /etc/neutron/neutron.conf && echo neutron-conf-exec >> /etc/contrail/contrail_openstack_exec.out",
            onlyif => "test -f /etc/neutron/neutron.conf",
            unless  => "grep -qx neutron-os-conf-exec /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => "true"
        }
    }

    if ! defined(Exec["quantum-conf-exec"]) {
        exec { "quantum-conf-exec":
            command => "sed -i 's/rpc_backend\s*=\s*quantum.openstack.common.rpc.impl_qpid/#rpc_backend = quantum.openstack.common.rpc.impl_qpid/g' /etc/quantum/quantum.conf && echo quantum-conf-exec >> /etc/contrail/contrail_openstack_exec.out",
            onlyif => "test -f /etc/quantum/quantum.conf",
            unless  => "grep -qx quantum-conf-exec /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => "true"
        }
    }

    # Execute keystone-server-setup script
    openstack-scripts { ["keystone-server-setup", "glance-server-setup", "cinder-server-setup", "nova-server-setup"]: }

    if (!defined(File["/etc/haproxy/haproxy.cfg"])) and ( $contrail_haproxy == "enable" )  {
    	file { "/etc/haproxy/haproxy.cfg":
       	   ensure  => present,
           mode => 0755,
           owner => root,
           group => root,
           source => "puppet:///modules/$module_name/$hostname.cfg"
        }
        exec { "haproxy-exec":
                command => "sed -i 's/ENABLED=.*/ENABLED=1/g' /etc/default/haproxy;",
                provider => shell,
                logoutput => "true",
                require => File["/etc/haproxy/haproxy.cfg"]
        }
        service { "haproxy" :
            enable => true,
            require => [File["/etc/default/haproxy"],
                        File["/etc/haproxy/haproxy.cfg"]],
            ensure => running
        }
    }

    setup-keystone-2 {"setup_keystone_2":}
    
    exec { "update-mysql-file1" :
        command => "sed -i -e 's/bind-address/#bind-address/g' /etc/mysql/my.cnf && echo update-mysql-file1 >> /etc/contrail/contrail_openstack_exec.out",
        require =>  package["contrail-openstack"],
        onlyif => "test -f /etc/mysql/my.cnf",
        unless  => "grep -qx update-mysql-file1 /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => 'true',
        before => Service["mysqld"]
    }

    exec { "restart-supervisor-openstack":
        command => "service supervisor-openstack restart && echo restart-supervisor-openstack >> /etc/contrail/contrail_openstack_exec.out",
        unless  => "grep -qx restart-supervisor-openstack /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => "true"
    }
    # Ensure the services needed are running.
    service { "mysqld" :
        enable => true,
        require => [ Package['contrail-openstack'] ],
        ensure => running,
    }


    setup-keystone-service {"setup_keystone_service":}
    service { "memcached" :
        enable => true,
        ensure => running,
    }
    ->
    contrail::lib::report_status { "openstack_completed": state => "openstack_completed" }


    Package['contrail-openstack']->File['/etc/contrail/contrail_setup_utils/api-paste.sh']->Exec['exec-api-paste']->Exec['exec-openstack-qpid-rabbitmq-hostname']->File["/etc/contrail/ctrl-details"]->File["/etc/contrail/service.token"]->Openstack-scripts["keystone-server-setup"]->Openstack-scripts["glance-server-setup"]->Openstack-scripts["cinder-server-setup"]->Openstack-scripts["nova-server-setup"]->Setup-keystone-2["setup_keystone_2"]->Setup-keystone-service['setup_keystone_service']->Service['mysqld']->Service['memcached']->Exec['neutron-os-conf-exec']->Exec['dashboard-local-settings-3']->Exec['dashboard-local-settings-4']->Exec['restart-supervisor-openstack']

}
