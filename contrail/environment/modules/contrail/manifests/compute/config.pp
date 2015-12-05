class contrail::compute::config(
    $host_control_ip = $::contrail::params::host_ip,
    $config_ip = $::contrail::params::config_ip_list[0],
    $openstack_ip = $::contrail::params::openstack_ip_list[0],
    $control_ip_list = $::contrail::params::control_ip_list,
    $compute_ip_list = $::contrail::params::compute_ip_list,
    $keystone_ip = $::contrail::params::keystone_ip,
    $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol,
    $keystone_auth_port = $::contrail::params::keystone_auth_port,
    $openstack_manage_amqp = $::contrail::params::openstack_manage_amqp,
    $amqp_server_ip = $::contrail::params::amqp_server_ip,
    $openstack_mgmt_ip = $::contrail::params::openstack_mgmt_ip_list_to_use[0],
    $neutron_service_protocol = $::contrail::params::neutron_service_protocol,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $haproxy = $::contrail::params::haproxy,
    $host_non_mgmt_ip = $::contrail::params::host_non_mgmt_ip,
    $host_non_mgmt_gateway = $::contrail::params::host_non_mgmt_gateway,
    $metadata_secret = $::contrail::params::metadata_secret,
    $quantum_port = $::contrail::params::quantum_port,
    $quantum_service_protocol = $::contrail::params::quantum_service_protocol,
    $internal_vip = $::contrail::params::internal_vip,
    $external_vip = $::contrail::params::external_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $vmware_ip = $::contrail::params::vmware_ip,
    $vmware_username = $::contrail::params::vmware_username,
    $vmware_password = $::contrail::params::vmware_password,
    $vmware_vswitch = $::contrail::params::vmware_vswitch,
    $vgw_public_subnet = $::contrail::params::vgw_public_subnet,
    $vgw_public_vn_name = $::contrail::params::vgw_public_vn_name,
    $vgw_interface = $::contrail::params::vgw_interface,
    $vgw_gateway_routes = $::contrail::params::vgw_gateway_routes,
    $nfs_server = $::contrail::params::nfs_server,
    $orchestrator = $::contrail::params::orchestrator,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $contrail_host_roles = $::contrail::params::host_roles,
    $enable_lbass =  $::contrail::params::enable_lbass,
)  {
    $config_ip_to_use = $::contrail::params::config_ip_to_use
    $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use
    $amqp_server_ip_to_use = $::contrail::params::amqp_server_ip_to_use

    # set number of control nodes.
    $number_control_nodes = size($control_ip_list)
    # Set vhost_ip and multi_net flag
    if ($host_non_mgmt_ip != '') {
        $multinet_opt = '--multi_net'
        $vhost_ip = $host_non_mgmt_ip
        $contrail_compute_dev = get_device_name($host_control_ip)
        $contrail_gway = $host_non_mgmt_gateway
    } else {
        $multinet_opt = ''
        $vhost_ip = $host_control_ip
        $contrail_compute_dev = ''
        $contrail_gway = $contrail_gateway
    }
    $physical_dev = get_device_name($vhost_ip)
    if ($physical_dev != 'vhost0') {
        $contrail_dev = $physical_dev
    } else {
        $contrail_dev_mac = inline_template("<%= scope.lookupvar('macaddress_' + @physical_dev) %>")
        $contrail_dev = get_device_name_by_mac($contrail_dev_mac)
    }

    if ($physical_dev == undef) {
        fail('contrail device is not found')
    }

    # Get Mac, netmask and gway
    $contrail_macaddr = inline_template("<%= scope.lookupvar('macaddress_' + @physical_dev) %>")
    $contrail_netmask = inline_template("<%= scope.lookupvar('netmask_' + @physical_dev) %>")
    $contrail_cidr = convert_netmask_to_cidr($contrail_netmask)

    if ($haproxy == true) {
        $quantum_ip = '127.0.0.1'
        $discovery_ip = '127.0.0.1'
    } else {
        $quantum_ip = $config_ip_to_use
        $discovery_ip = $config_ip_to_use
    }

    $vmware_physical_intf = 'eth1'
    if ( $vmware_ip != '' ) {
        $hypervisor_type = 'vmware'
    } else {
        $hypervisor_type = 'kvm'
    }

    if 'tsn' in $contrail_host_roles {
        $contrail_agent_mode = 'tsn'
        $contrail_router_type = '--router_type tor-service-node'
        $nova_compute_status = 'false'
    } else {
        $contrail_agent_mode = ""
        $contrail_router_type = ''
        $nova_compute_status = 'true'
    }
    # Debug Print all variable values
    notify {"host_control_ip = ${host_control_ip}":; } ->
    notify {"config_ip = ${config_ip}":; } ->
    notify {"openstack_ip = ${openstack_ip}":; } ->
    notify {"control_ip_list = ${control_ip_list}":; } ->
    notify {"compute_ip_list = ${compute_ip_list}":; } ->
    notify {"keystone_ip = ${keystone_ip}":; } ->
    notify {"keystone_auth_protocol = ${keystone_auth_protocol}":; } ->
    notify {"keystone_auth_port = ${keystone_auth_port}":; } ->
    notify {"openstack_manage_amqp = ${openstack_manage_amqp}":; } ->
    notify {"amqp_server_ip = ${amqp_server_ip}":; } ->
    notify {"openstack_mgmt_ip = ${openstack_mgmt_ip}":; } ->
    notify {"amqp_server_ip_to_use = ${amqp_server_ip_to_use}":; } ->
    notify {"neutron_service_protocol = ${neutron_service_protocol}":; } ->
    notify {"keystone_admin_user = ${keystone_admin_user}":; } ->
    notify {"keystone_admin_password = ${keystone_admin_password}":; } ->
    notify {"keystone_admin_tenant = ${keystone_admin_tenant}":; } ->
    notify {"haproxy = ${haproxy}":; } ->
    notify {"host_non_mgmt_ip = ${host_non_mgmt_ip}":; } ->
    notify {"host_non_mgmt_gateway = ${host_non_mgmt_gateway}":; } ->
    notify {"metadata_secret = ${metadata_secret}":; } ->
    notify {"internal_vip = ${internal_vip}":; } ->
    notify {"external_vip = ${external_vip}":; } ->
    notify {"contrail_internal_vip = ${contrail_internal_vip}":; } ->
    notify {"vmware_ip = ${vmware_ip}":; } ->
    notify {"vmware_username = ${vmware_username}":; } ->
    notify {"vmware_password = ${vmware_password}":; } ->
    notify {"vmware_vswitch = ${vmware_vswitch}":; } ->
    notify {"vgw_public_subnet = ${vgw_public_subnet}":; } ->
    notify {"vgw_public_vn_name = ${vgw_public_vn_name}":; } ->
    notify {"vgw_interface = ${vgw_interface}":; } ->
    notify {"vgw_gateway_routes = ${vgw_gateway_routes}":; } ->
    notify {"nfs_server = ${nfs_server}":; } ->
    notify {"keystone_ip_to_use = ${keystone_ip_to_use}":; } ->
    notify {"config_ip_to_use = ${config_ip_to_use}":; } ->
    notify {"number_control_nodes = ${number_control_nodes}":; } ->
    notify {"multinet_opt = ${multinet_opt}":; } ->
    notify {"vhost_ip = ${vhost_ip}":; } ->
    notify {"physical_dev = ${physical_dev}":; } ->
    notify {"contrail_compute_dev = ${contrail_compute_dev}":; } ->
    notify {"contrail_macaddr = ${contrail_macaddr}":; } ->
    notify {"contrail_netmask = ${contrail_netmask}":; } ->
    notify {"contrail_cidr = ${contrail_cidr}":; } ->
    notify {"contrail_gway = ${contrail_gway}":; } ->
    notify {"contrail_gateway = ${contrail_gateway}":; } ->
    notify {"quantum_port = ${quantum_port}":; } ->
    notify {"quantum_ip = ${quantum_ip}":; } ->
    notify {"quantum_service_protocol = ${quantum_service_protocol}":; } ->
    notify {"discovery_ip = ${discovery_ip}":; } ->
    notify {"hypervisor_type = ${hypervisor_type}":; } ->
    notify {"vmware_physical_intf = ${vmware_physical_intf}":; }

    if ($operatingsystem == "Ubuntu"){
        if 'tsn' in $contrail_host_roles {
            file { "/etc/init/nova-compute.override":
                ensure => present,
                content => "manual",
            }
        }
    }

    # Install interface rename package for centos.
    if (inline_template('<%= @operatingsystem.downcase %>') == 'centos') {
        contrail::lib::contrail_rename_interface { 'centos-rename-interface' :
        }
    }
    # for storage
    if ($nfs_server == 'xxx' and $host_control_ip == $compute_ip_list[0] ) {
        exec { 'create-nfs' :
            command   => 'mkdir -p /var/tmp/glance-images/ && chmod 777 /var/tmp/glance-images/ && echo \"/var/tmp/glance-images *(rw,sync,no_subtree_check)\" >> /etc/exports && sudo /etc/init.d/nfs-kernel-server restart && echo create-nfs >> /etc/contrail/contrail_compute_exec.out ',
            unless    => 'grep -qx create-nfs  /etc/contrail/contrail_compute_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
        }
    }

    $nova_params = {
      'DEFAULT/neutron_admin_auth_url'=> {   value => "http://${keystone_ip_to_use}:5000/v2.0", },
      'DEFAULT/neutron_admin_tenant_name'=>{ value => 'services', },
      'DEFAULT/neutron_admin_password'=>  {  value => "${keystone_admin_password}" },
      'keystone_authtoken/admin_password'=>{ value => "${keystone_admin_password}" }
    }

    create_resources(nova_config,$nova_params, {} )

    # set rpc backend in nova.conf
    exec { 'exec-compute-update-nova-conf' :
        command   => "sed -i \"s/^rpc_backend = nova.openstack.common.rpc.impl_qpid/#rpc_backend = nova.openstack.common.rpc.impl_qpid/g\" /etc/nova/nova.conf && echo exec-update-nova-conf >> /etc/contrail/contrail_common_exec.out",
        unless    => ['[ ! -f /etc/nova/nova.conf ]',
                    'grep -qx exec-update-nova-conf /etc/contrail/contrail_common_exec.out'],
        provider  => shell,
        logoutput => $contrail_logoutput
    }

    if ! defined(Exec['neutron-conf-exec']) {
        exec { 'neutron-conf-exec':
            command   => "sudo sed -i 's/rpc_backend\s*=\s*neutron.openstack.common.rpc.impl_qpid/#rpc_backend = neutron.openstack.common.rpc.impl_qpid/g' /etc/neutron/neutron.conf && echo neutron-conf-exec >> /etc/contrail/contrail_openstack_exec.out",
            onlyif    => 'test -f /etc/neutron/neutron.conf',
            unless    => 'grep -qx neutron-conf-exec /etc/contrail/contrail_openstack_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
        }
    }

    if ! defined(Exec['quantum-conf-exec']) {
        exec { 'quantum-conf-exec':
            command   => "sudo sed -i 's/rpc_backend\s*=\s*quantum.openstack.common.rpc.impl_qpid/#rpc_backend = quantum.openstack.common.rpc.impl_qpid/g' /etc/quantum/quantum.conf && echo quantum-conf-exec >> /etc/contrail/contrail_openstack_exec.out",
            onlyif    => 'test -f /etc/quantum/quantum.conf',
            unless    => 'grep -qx quantum-conf-exec /etc/contrail/contrail_openstack_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
        }
    }

    # Update modprobe.conf
    if inline_template('<%= @operatingsystem.downcase %>') == 'centos' {
        file { '/etc/modprobe.conf' :
            ensure  => present,
            content => template("${module_name}/modprobe.conf.erb")
        }
    }

    file { '/etc/contrail/contrail_setup_utils/add_dev_tun_in_cgroup_device_acl.sh':
        ensure => present,
        mode   => '0755',
        owner  => root,
        group  => root,
        source => "puppet:///modules/${module_name}/add_dev_tun_in_cgroup_device_acl.sh"
    } ->
    exec { 'add_dev_tun_in_cgroup_device_acl' :
        command   => './add_dev_tun_in_cgroup_device_acl.sh && echo add_dev_tun_in_cgroup_device_acl >> /etc/contrail/contrail_compute_exec.out',
        cwd       => '/etc/contrail/contrail_setup_utils/',
        unless    => 'grep -qx add_dev_tun_in_cgroup_device_acl /etc/contrail/contrail_compute_exec.out',
        provider  => shell,
        logoutput => $contrail_logoutput
    }

    file { '/etc/contrail/vrouter_nodemgr_param' :
        ensure  => present,
        require => Package['contrail-openstack-vrouter'],
        content => template("${module_name}/vrouter_nodemgr_param.erb"),
    }

    # Ensure ctrl-details file is present with right content.
    if ! defined(File['/etc/contrail/ctrl-details']) {
        file { '/etc/contrail/ctrl-details' :
            ensure  => present,
            content => template("${module_name}/ctrl-details.erb"),
        }
    }

    if ! defined(File['/opt/contrail/bin/set_rabbit_tcp_params.py']) {
        # check_wsrep
        file { '/opt/contrail/bin/set_rabbit_tcp_params.py' :
            ensure => present,
            mode   => '0755',
            group  => root,
            source => "puppet:///modules/${module_name}/set_rabbit_tcp_params.py"
        } ->
        exec { 'exec_set_rabbitmq_tcp_params' :
            command   => 'python /opt/contrail/bin/set_rabbit_tcp_params.py && echo exec_set_rabbitmq_tcp_params >> /etc/contrail/contrail_openstack_exec.out',
            cwd       => '/opt/contrail/bin/',
            unless    => 'grep -qx exec_set_rabbitmq_tcp_params /etc/contrail/contrail_openstack_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
        }
    }

    if ($physical_dev != undef and $physical_dev != 'vhost0') {
        $update_dev_net_cmd = "/bin/bash -c \"python /etc/contrail/contrail_setup_utils/update_dev_net_config_files.py --vhost_ip ${vhost_ip} ${multinet_opt} --dev \'${physical_dev}\' --compute_dev \'${contrail_compute_dev}\' --netmask \'${contrail_netmask}\' --gateway \'${contrail_gway}\' --cidr \'${contrail_cidr}\' --host_non_mgmt_ip \'${host_non_mgmt_ip}\' --mac ${contrail_macaddr} && echo update-dev-net-config >> /etc/contrail/contrail_compute_exec.out\""

        notify { "Update dev net config is ${update_dev_net_cmd}":; }

        file { '/etc/contrail/contrail_setup_utils/update_dev_net_config_files.py':
            ensure => present,
            mode   => '0755',
            owner  => root,
            group  => root,
            source => "puppet:///modules/${module_name}/update_dev_net_config_files.py"
        } ->
        exec { 'update-dev-net-config' :
            command   => $update_dev_net_cmd,
            unless    => 'grep -qx update-dev-net-config /etc/contrail/contrail_compute_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
        }
    }

    file { '/etc/contrail/agent_param' :
        ensure  => present,
        content => template("${module_name}/agent_param.tmpl.erb"),
    }
    if ! defined(File['/etc/contrail/vnc_api_lib.ini']) {
        file { '/etc/contrail/vnc_api_lib.ini' :
            ensure  => present,
            content => template("${module_name}/vnc_api_lib.ini.erb"),
        }
    }

    contrail_vrouter_agent_config {
      'DISCOVERY/server' : value => "$discovery_ip";
      'DISCOVERY/max_control_nodes' : value => "$number_control_nodes";
      'HYPERVISOR/type' : value => "$hypervisor_type";
      'HYPERVISOR/vmware_physical_interface' : value => "$vmware_physical_intf";
      'NETWORKS/control_network_ip' : value => "$host_control_ip";
      'VIRTUAL-HOST-INTERFACE/name' : value => "vhost0";
      'VIRTUAL-HOST-INTERFACE/ip' : value => "$host_control_ip/$contrail_cidr";
      'VIRTUAL-HOST-INTERFACE/gateway' : value => "$contrail_gway";
      'VIRTUAL-HOST-INTERFACE/physical_interface' : value => "$contrail_dev";
      'SERVICE-INSTANCE/netns_command' : value => "/usr/local/bin/opencontrail-vrouter-netns";
    }
    contrail_vrouter_agent_config {
      'VIRTUAL-HOST-INTERFACE/compute_node_address' : ensure => 'absent';
    }

    if $contrail_agent_mode == 'tsn' {
      contrail_vrouter_agent_config { 'DEFAULT/agent_mode' : value => "tsn"; }
    }

    contrail_vrouter_nodemgr_config {
      'DISCOVERY/server' : value => "$discovery_ip";
      'DISCOVERY/port' : value => '5998';
    }

    file { '/opt/contrail/utils/provision_vrouter.py':
        ensure => present,
        mode   => '0755',
        owner  => root,
        group  => root
    }
    ->
    exec { 'add-vnc-config' :
        command   => "/bin/bash -c \"python /opt/contrail/utils/provision_vrouter.py --host_name ${::hostname} --host_ip ${host_control_ip} --api_server_ip ${config_ip_to_use} --oper add --admin_user ${keystone_admin_user} --admin_password ${keystone_admin_password} --admin_tenant_name ${keystone_admin_tenant} --openstack_ip ${openstack_ip} && echo add-vnc-config >> /etc/contrail/contrail_compute_exec.out\"",
        unless    => 'grep -qx add-vnc-config /etc/contrail/contrail_compute_exec.out',
        provider  => shell,
        logoutput => $contrail_logoutput
    }
    ->
    file { '/opt/contrail/bin/compute-server-setup.sh':
        ensure  => present,
        mode    => '0755',
        owner   => root,
        group   => root,
        require => File['/etc/contrail/ctrl-details'],
    }
    ->
    exec { 'setup-compute-server-setup' :
        command   => '/opt/contrail/bin/compute-server-setup.sh; echo setup-compute-server-setup >> /etc/contrail/contrail_compute_exec.out',
        unless    => 'grep -qx setup-compute-server-setup /etc/contrail/contrail_compute_exec.out',
        provider  => shell,
        logoutput => $contrail_logoutput
    }
    ->
    reboot { 'compute':
      apply => "immediately",
      subscribe       => Exec ["setup-compute-server-setup"],
      timeout => 0,
    }
    # Now reboot the system
    if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
        exec { 'cp-ifcfg-file' :
            command   => 'cp -f /etc/contrail/ifcfg-* /etc/sysconfig/network-scripts && echo cp-ifcfg-file >> /etc/contrail/contrail_compute_exec.out',
            unless    => 'grep -qx cp-ifcfg-file /etc/contrail/contrail_compute_exec.out',
            provider  => 'shell',
            logoutput => $contrail_logoutput
        } -> Reboot['compute']
    }
}
