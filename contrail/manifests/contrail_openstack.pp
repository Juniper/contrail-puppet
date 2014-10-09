class __$version__::contrail_openstack {

define openstack-scripts {
    file { "/opt/contrail/contrail_installer/contrail_setup_utils/${title}.sh":
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
    }
    exec { "setup-${title}" :
        command => "/opt/contrail/contrail_installer/contrail_setup_utils/${title}.sh $operatingsystem && echo setup-${title} >> /etc/contrail/contrail_openstack_exec.out",
        require => [ File["/opt/contrail/contrail_installer/contrail_setup_utils/${title}.sh"],
                     File["/etc/contrail/ctrl-details"] ],
        unless  => "grep -qx setup-${title} /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => "true"
    }
}

# Following variables need to be set for this resource.
# Those specified with value assiged are optional, if not
# set the assigned value below is used.
#     $contrail_openstack_ip
#     $contrail_keystone_ip = $contrail_openstack_ip
#     $contrail_config_ip
#     $contrail_compute_ip
#     $contrail_openstack_mgmt_ip
#     $contrail_service_token
#     $contrail_ks_admin_passwd
#     $contrail_haproxy
#     $contrail_amqp_server_ip="127.0.0.1"
#     $contrail_ks_auth_protocol="http"
#     $contrail_quantum_service_protocol="http"
#     $contrail_ks_auth_port="35357"
define contrail_openstack (
        $contrail_keystone_ip = $contrail_openstack_ip,
        $contrail_amqp_server_ip= $contrail_amqp_server_ip,
        $contrail_ks_auth_protocol="http",
        $contrail_quantum_service_protocol="http",
        $contrail_ks_auth_port="35357"
    ) {

    $contrail_vm_ip = ""
    $contrail_vm_username = ""
    $contrail_vm_passwd = ""
    $contrail_vswitch = ""

    __$version__::contrail_common::report_status {"openstack_started": state => "openstack_started"}
    ->
    # list of packages
    package { 'contrail-openstack' : ensure => present,}
    ->
    __$version__::contrail_common::increase_ulimits {"increase_ulimits_openstack":}

    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - python-contrail, openstack-dashboard, contrail-openstack-dashboard, glance, keystone, nova-api, nova-common,
    #                     nova-conductor, nova-console, nova-objectstore, nova-scheduler, cinder-api, cinder-common, cinder-scheduler,
    #                     mysql-server, contrail-setup, memcached, nova-novncproxy, nova-consoleauth, python-m2crypto, haproxy,
    #                     rabbitmq-server, apache2, libapache2-mod-wsgi, python-memcache, python-iniparse, python-qpid, euca2ools
    # For Centos/Fedora - contrail-api-lib, openstack-dashboard, contrail-openstack-dashboard, openstack-glance, openstack-keystone,
    #                     openstack-nova, openstack-cinder, mysql-server, contrail-setup, memcached, openstack-nova-novncproxy,
    #                     python-glance, python-glanceclient, python-importlib, euca2ools, m2crypto, qpid-cpp-server,
    #                     haproxy, rabbitmq-server


    if ($operatingsystem == "Centos" or $operatingsystem == "Fedora") {
        exec { "dashboard-local-settings-1" :
            command => "sudo sed -i 's/ALLOWED_HOSTS =/#ALLOWED_HOSTS =/g' /etc/openstack_dashboard/local_settings && echo dashboard-local-settings-1 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack_dashboard/local_settings",
            unless  => "grep -qx dashboard-local-settings-1 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }
        exec { "dashboard-local-settings-2" :
            command => "sudo sed -i 's/ALLOWED_HOSTS =/#ALLOWED_HOSTS =/g' /etc/openstack-dashboard/local_settings && echo dashboard-local-settings-2 >> /etc/contrail/contrail_openstack_exec.out",
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
            command => "sudo sed -i '/HORIZON_CONFIG.*customization_module.*/d' /etc/openstack-dashboard/local_settings.py && echo \"$line1\"  >> /etc/openstack-dashboard/local_settings.py  && echo dashboard-local-settings-3 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack-dashboard/local_settings.py",
            unless  => "grep -qx dashboard-local-settings-3 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }

        $line2="LOGOUT_URL=\'/horizon/auth/logout/\'"
        exec { "dashboard-local-settings-4" :

            command => "sudo sed -i '/LOGOUT_URL.*/d' /etc/openstack-dashboard/local_settings.py && echo \"$line2\" >> /etc/openstack-dashboard/local_settings.py && service apache2 restart && echo dashboard-local-settings-4 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack-dashboard/local_settings.py",
            unless  => "grep -qx dashboard-local-settings-4 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }
    }
    if ($operatingsystem == "Centos") {
        exec { "dashboard-local-settings-3" :
            command => "sudo sed -i '/HORIZON_CONFIG.*customization_module.*/d' /etc/openstack-dashboard/local_settings && echo HORIZON_CONFIG['customization_module'] = 'contrail_openstack_dashboard.overrides' >> etc/openstack-dashboard/local_settings  && echo dashboard-local-settings-3 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack-dashboard/local_settings",
            unless  => "grep -qx dashboard-local-settings-3 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }

        exec { "dashboard-local-settings-4" :
            command => "sudo sed -i '/LOGOUT_URL.*/d' etc/openstack-dashboard/local_settings && echo LOGOUT_URL='/horizon/auth/logout/' >> etc/openstack-dashboard/local_settings && service httpd restart && echo dashboard-local-settings-4 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack-dashboard/local_settings",
            unless  => "grep -qx dashboard-local-settings-4 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }
    }

    exec { "update-nova-conf-file" :
        command => "sudo sed -i 's/rpc_backend = nova.openstack.common.rpc.impl_qpid/#rpc_backend = nova.openstack.common.rpc.impl_qpid/g' /etc/nova/nova.conf && echo update-nova-conf-file >> /etc/contrail/contrail_openstack_exec.out",
        require =>  package["contrail-openstack"],
        onlyif => "test -f /etc/nova/nova.conf",
        unless  => "grep -qx update-nova-conf-file /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => 'true'
    }

    ##Chhandak Added this section to update nova.conf with corect rabit_host ip
    exec { "update-nova-conf-file1" :
        #command => "sudo sed -i 's/#rabbit_host\s*=\s*127.0.0.1/rabbit_host = $contrail_amqp_server_ip/g' /etc/nova/nova.conf && echo update-nova-conf-file1 >> /etc/contrail/contrail_openstack_exec.out",
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

    exec { "update-cinder-conf-file" :
        command => "sudo sed -i 's/rpc_backend = cinder.openstack.common.rpc.impl_qpid/#rpc_backend = cinder.openstack.common.rpc.impl_qpid/g' /etc/cinder/cinder.conf && echo update-cinder-conf-file >> /etc/contrail/contrail_openstack_exec.out",
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
		$quantum_ip = $contrail_config_ip
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

    if ! defined(Exec["neutron-conf-exec"]) {
        exec { "neutron-conf-exec":
            command => "sudo sed -i 's/rpc_backend\s*=\s*neutron.openstack.common.rpc.impl_qpid/#rpc_backend = neutron.openstack.common.rpc.impl_qpid/g' /etc/neutron/neutron.conf && echo neutron-conf-exec >> /etc/contrail/contrail_openstack_exec.out",
            onlyif => "test -f /etc/neutron/neutron.conf",
            unless  => "grep -qx neutron-conf-exec /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => "true"
        }
    }

    if ! defined(Exec["quantum-conf-exec"]) {
        exec { "quantum-conf-exec":
            command => "sudo sed -i 's/rpc_backend\s*=\s*quantum.openstack.common.rpc.impl_qpid/#rpc_backend = quantum.openstack.common.rpc.impl_qpid/g' /etc/quantum/quantum.conf && echo quantum-conf-exec >> /etc/contrail/contrail_openstack_exec.out",
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
                command => "sudo sed -i 's/ENABLED=.*/ENABLED=1/g' /etc/default/haproxy;",
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

    # repeat keystone setup (workaround for now) Needs to be fixed .. Abhay
    if ($operatingsystem == "Ubuntu") {
	    exec { "setup-keystone-server-2setup" :
		    command => "/opt/contrail/contrail_installer/contrail_setup_utils/keystone-server-setup.sh $operatingsystem && echo setup-keystone-server-2setup >> /etc/contrail/contrail_openstack_exec.out",
		    require => [ File["/opt/contrail/contrail_installer/contrail_setup_utils/keystone-server-setup.sh"],
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
    ##Chhandak Added this section to update /etc/mysql/my.cnf to remove bind address
    exec { "update-mysql-file1" :
        command => "sudo sed -i -e 's/bind-address/#bind-address/g' /etc/mysql/my.cnf && echo update-mysql-file1 >> /etc/contrail/contrail_openstack_exec.out",
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

    service { "openstack-keystone" :
        enable => true,
        require => [ Package['contrail-openstack'],
                     Openstack-scripts["nova-server-setup"] ],
        ensure => running,
    }
    service { "memcached" :
        enable => true,
        ensure => running,
    }
    ->
    __$version__::contrail_common::report_status {"openstack_completed": state => "openstack_completed"}
    Package['contrail-openstack']->File['/etc/contrail/contrail_setup_utils/api-paste.sh']->Exec['exec-api-paste']->Exec['exec-openstack-qpid-rabbitmq-hostname']->File["/etc/contrail/ctrl-details"]->File["/etc/contrail/service.token"]->Openstack-scripts["keystone-server-setup"]->Openstack-scripts["glance-server-setup"]->Openstack-scripts["cinder-server-setup"]->Openstack-scripts["nova-server-setup"]->Exec['setup-keystone-server-2setup']->Service['openstack-keystone']->Service['mysqld']->Service['memcached']->Exec['neutron-conf-exec']->Exec['dashboard-local-settings-3']->Exec['dashboard-local-settings-4']->Exec['restart-supervisor-openstack']
}
# end of user defined type contrail_openstack.

}
