class contrail::config::config (
    $host_control_ip = $::contrail::params::host_ip,
    $collector_ip = $::contrail::params::collector_ip_list[0],
    $database_ip_list = $::contrail::params::database_ip_list,
    $control_ip_list = $::contrail::params::control_ip_list,
    $openstack_ip = $::contrail::params::openstack_ip_list[0],
    $uuid = $::contrail::params::uuid,
    $keystone_ip = $::contrail::params::keystone_ip,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
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
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $contrail_keystone_auth_conf = $contrail::params::contrail_keystone_auth_conf
) {
    # Main code for class starts here
    if $use_certs == true {
      $ifmap_server_port = '8444'
    } else {
      $ifmap_server_port = '8443'
    }

    $analytics_api_port = '8081'
    $contrail_plugin_file = '/etc/neutron/plugins/opencontrail/ContrailPlugin.ini'
    $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use
    $amqp_server_ip_to_use = $::contrail::params::amqp_server_ip_to_use

    if $multi_tenancy == true {
        $memcached_opt = 'memcache_servers=127.0.0.1:11211'
    } else {
        $memcached_opt = ''
    }
    # Initialize the multi tenancy option will update latter based on vns argument
    if ($multi_tenancy == true) {
        $mt_options = 'admin,$keystone_admin_password,$keystone_admin_tenant'
    } else {
        $mt_options = 'None'
    }

    # Supervisor contrail-api.ini
    $api_port_base = '910'
    # Supervisor contrail-discovery.ini
    $disc_port_base = '911'
    $disc_nworkers = $api_nworkers

    # Set number of config nodes
    $cfgm_number = size($config_ip_list)

    if ( $host_control_ip == $config_ip_list[0]) {
        $master = 'yes'
    } else {
        $master = 'no'
    }

    File {
      ensure => 'present'
    }

    case $::operatingsystem {
        Ubuntu: {
            file {['/etc/init/supervisor-config.override',
                   '/etc/init/neutron-server.override']: ensure => absent}
            ->
            file { '/etc/contrail/supervisord_config_files/contrail-api.ini' :
                content => template("${module_name}/contrail-api.ini.erb"),
            }
            ->
            file { '/etc/contrail/supervisord_config_files/contrail-discovery.ini' :
                content => template("${module_name}/contrail-discovery.ini.erb"),
            }
            ->
            # Below is temporary to work-around in Ubuntu as Service resource fails
            # as upstart is not correctly linked to /etc/init.d/service-name
            file { '/etc/init.d/supervisor-config':
                ensure => link,
                target => '/lib/init/upstart-job',
            }
        }
        Centos: {
            # notify { "OS is Ubuntu":; }
            file { '/etc/contrail/supervisord_config_files/contrail-api.ini' :
                content => template("${module_name}/contrail-api-centos.ini.erb"),
            }
            ->
            file { '/etc/contrail/supervisord_config_files/contrail-discovery.ini' :
                content => template("${module_name}/contrail-discovery-centos.ini.erb"),
            }
        }
        Fedora: {
            file { '/etc/contrail/supervisord_config_files/contrail-api.ini' :
                content => template("${module_name}/contrail-api-centos.ini.erb"),
            }
            ->
            file { '/etc/contrail/supervisord_config_files/contrail-discovery.ini' :
                content => template("${module_name}/contrail-discovery-centos.ini.erb"),
            }
        }
        default: {
    # notify { "OS is $operatingsystem":; }
        }
    }

    # Ensure ctrl-details file is present with right content.
    if ! defined(File['/etc/contrail/ctrl-details']) {
        if $haproxy == true {
            $quantum_ip = '127.0.0.1'
        } else {
            $quantum_ip = $host_control_ip
        }

        file { '/etc/contrail/ctrl-details' :
            content => template("${module_name}/ctrl-details.erb"),
        }
    }

    if !defined(File['/etc/contrail/openstackrc']) {
        file { '/etc/contrail/openstackrc' :
            content => template("${module_name}/openstackrc.erb"),
            before => Exec['neutron-conf-exec']
        }
    }

    include ::contrail::keystone

    exec { 'neutron-conf-exec':
        command   => "sudo sed -i 's/rpc_backend\s*=\s*neutron.openstack.common.rpc.impl_qpid/#rpc_backend = neutron.openstack.common.rpc.impl_qpid/g' /etc/neutron/neutron.conf && echo neutron-conf-exec >> /etc/contrail/contrail_openstack_exec.out",
        onlyif    => 'test -f /etc/neutron/neutron.conf',
        unless    => 'grep -qx neutron-conf-exec /etc/contrail/contrail_openstack_exec.out',
        provider  => shell,
        logoutput => $contrail_logoutput
    }
    ->
    #form the sudoers
    file { '/etc/sudoers.d/contrail_sudoers' :
        mode   => '0440',
        group  => root,
        source => "puppet:///modules/${module_name}/contrail_sudoers"
    }
    ->
    # Ensure log4j.properties file is present with right content.
    file { '/etc/ifmap-server/log4j.properties' :
        content => template("${module_name}/log4j.properties.erb"),
    }
    ->
    # Ensure authorization.properties file is present with right content.
    file { '/etc/ifmap-server/authorization.properties' :
        content => template("${module_name}/authorization.properties.erb"),
    }
    ->
    # Ensure basicauthusers.proprties file is present with right content.
    file { '/etc/ifmap-server/basicauthusers.properties' :
        content => template("${module_name}/basicauthusers.properties.erb"),
    }
    ->
    # Ensure publisher.properties file is present with right content.
    file { '/etc/ifmap-server/publisher.properties' :
        content => template("${module_name}/publisher.properties.erb"),
    }
    ->
    # Ensure all config files with correct content are present.
    file { '/etc/contrail/contrail-api.conf' :
        content => template("${module_name}/contrail-api.conf.erb"),
    }
    ->
    file { '/etc/contrail/contrail-config-nodemgr.conf' :
        content => template("${module_name}/contrail-config-nodemgr.conf.erb"),
    }
    ->
    file { '/etc/contrail/contrail-schema.conf' :
        content => template("${module_name}/contrail-schema.conf.erb"),
    }
    ->
    file { '/etc/contrail/contrail-svc-monitor.conf' :
        content => template("${module_name}/contrail-svc-monitor.conf.erb"),
    }
    ->
    file { '/etc/contrail/contrail-device-manager.conf' :
        content => template("${module_name}/contrail-device-manager.conf.erb"),
    }
    ->
    file { '/etc/contrail/contrail-discovery.conf' :
        content => template("${module_name}/contrail-discovery.conf.erb"),
    }
    ->
    file { '/etc/contrail/vnc_api_lib.ini' :
        content => template("${module_name}/vnc_api_lib.ini.erb"),
    }
    ->
    file { '/etc/contrail/contrail_plugin.ini' :
        content => template("${module_name}/contrail_plugin.ini.erb"),
    }
    ->
    # initd script wrapper for contrail-api
    file { '/etc/init.d/contrail-api' :
        mode    => '0777',
        content => template("${module_name}/contrail-api.svc.erb"),
    }
    ->
    file { '/etc/neutron/plugins/opencontrail/ContrailPlugin.ini' :
        content => template("${module_name}/contrail_plugin.ini.erb"),
    }
    -> exec { 'contrail-plugin-set-lbass-params':
        command   => "openstack-config --set ${contrail_plugin_file} COLLECTOR analytics_api_ip ${collector_ip} &&
                           openstack-config --set ${contrail_plugin_file} COLLECTOR analytics_api_port ${analytics_api_port} &&
                           echo exec_contrail_plugin_set_lbass_params >> /etc/contrail/contrail_config_exec.out",
        provider  => shell,
        logoutput => $contrail_logoutput
    }
    ->
    exec { 'config-neutron-server' :
        command   => "sudo sed -i '/NEUTRON_PLUGIN_CONFIG.*/d' /etc/default/neutron-server && echo \"${contrail_plugin_location}\" >> /etc/default/neutron-server && service neutron-server restart && echo config-neutron-server >> /etc/contrail/contrail_config_exec.out",
        onlyif    => 'test -f /etc/default/neutron-server',
        unless    => 'grep -qx config-neutron-server /etc/contrail/contrail_config_exec.out',
        provider  => shell,
        logoutput => $contrail_logoutput
    }
    ->
    # initd script wrapper for contrail-discovery
    file { '/etc/init.d/contrail-discovery' :
        mode    => '0777',
        content => template("${module_name}/contrail-discovery.svc.erb"),
    }

    # run setup-pki.sh script
    if $use_certs == true {
        file { '/etc/contrail_setup_utils/setup-pki.sh' :
            mode   => '0755',
            user   => root,
            group  => root,
            source => "puppet:///modules/${module_name}/setup-pki.sh"
        } ->
        exec { 'setup-pki' :
            command   => '/etc/contrail_setup_utils/setup-pki.sh /etc/contrail/ssl; echo setup-pki >> /etc/contrail/contrail_config_exec.out',
            unless    => 'grep -qx setup-pki /etc/contrail/contrail_config_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
        }
    }
    file { '/usr/bin/nodejs':
        ensure => link,
        target => '/usr/bin/node',
    } ->
    file { '/etc/contrail/quantum-server-setup.sh':
        mode    => '0755',
        owner   => root,
        group   => root,
        require => File['/etc/contrail/ctrl-details', '/etc/contrail/contrail-schema.conf', '/etc/contrail/contrail-svc-monitor.conf'],
        source => "puppet:///modules/${module_name}/quantum-server-setup.sh"
    }
    ->
    exec { 'setup-quantum-server-setup' :
        command  => "/bin/bash /etc/contrail/quantum-server-setup.sh ${::operatingsystem} && echo setup-quantum-server-setup >> /etc/contrail/contrail_config_exec.out",
        unless   => 'grep -qx setup-quantum-server-setup /etc/contrail/contrail_config_exec.out',
        provider => shell
    }

    $config_sysctl_settings = {
      'net.ipv4.tcp_keepalive_time' => { value => 5 },
      'net.ipv4.tcp_keepalive_probes' => { value => 5 },
      'net.ipv4.tcp_keepalive_intvl' => { value => 1 },
    }
    create_resources(sysctl::value,$config_sysctl_settings, {} )
}
