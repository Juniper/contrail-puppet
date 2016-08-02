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
    $enable_lbaas =  $::contrail::params::enable_lbaas,
    $xmpp_auth_enable =  $::contrail::params::xmpp_auth_enable,
    $xmpp_dns_auth_enable =  $::contrail::params::xmpp_dns_auth_enable,
    $enable_dpdk=  $::contrail::params::enable_dpdk,
    $contrail_rabbit_servers = $::contrail::params::contrail_rabbit_servers,
    $openstack_rabbit_servers = $::contrail::params::openstack_rabbit_servers,
    $openstack_amqp_ip_list = $::contrail::params::openstack_amqp_ip_list,
    $sriov = $::contrail::params::sriov,
    $nova_rabbit_hosts = $::contrail::params::nova_rabbit_hosts,
    $glance_management_address = $::contrail::params::os_glance_mgmt_address,
    $host_roles = $::contrail::params::host_roles,
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
        #when compute provision runs for the first time.
        #IP address is on the actual phsyical interface
        $contrail_dev = $physical_dev

        #find pci_address
        $intf_dict = $contrail_interfaces[$physical_dev]
        notify { "intf_dict = ${intf_dict}":; }
        if ( 'bond' in $physical_dev) {
          $pci_address = '0000:00:00.0'
        } elsif($intf_dict["parent"]) {
          #vlan interface
          $parent_intf = $contrail_interfaces[$intf_dict["parent"]]
          if ('bond' in $intf_dict["parent"]) {
            $pci_address = '0000:00:00.0'
          } else {
            $pci_address = $parent_intf["pci_address"]
          }
          notify { "has a parent":; }
          notify { "pci_address = ${pci_address}":; }
        } else {

          notify { "is master":; }
          $pci_address = $intf_dict["pci_address"]
          notify { "pci_address = ${pci_address}":; }
        }

    } else {
        #when compute provision runs the second time
        #vhost is already setup
        #in case of non dpdk setup old interface still exists
        #and details can de derived from that
        #in case of dpdk,actual physical inerface is taken away from the kernel
        #so get the details with the help of the facts

        $contrail_dev_mac = inline_template("<%= scope.lookupvar('macaddress_' + @physical_dev) %>")
        if ($enable_dpdk == false) {
            $contrail_dev = get_device_name_by_mac($contrail_dev_mac)
        } else {
            if ($contrail_dpdk_bind_if == "" or $contrail_dpdk_bind_if == undef) {
                fail('dpdk interface is not setup properly')
            }
            if ($contrail_dpdk_bind_pci_address == "" or $contrail_dpdk_bind_pci_address == undef) {
                fail('dpdk interface is not setup properly')
            }

            $contrail_dev = $contrail_dpdk_bind_if
            $pci_address = $contrail_dpdk_bind_pci_address
        }
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

    #variables used in templates for vrouter_agent.conf
    if ($enable_dpdk) {
        $contrail_work_mode = "dpdk"
    } else {
        $contrail_work_mode = "default"
    }

    if ($operatingsystem == "Ubuntu"){
        if 'tsn' in $contrail_host_roles {
            Notify["vmware_physical_intf = ${vmware_physical_intf}"] ->
            file { "/etc/init/nova-compute.override":
                ensure => present,
                content => "manual",
            }
        }
        if ($enable_dpdk == true) {
            #Looks like this is still seen as re-declaration by puppet
            /*
            Notify["vmware_physical_intf = ${vmware_physical_intf}"] ->
	    file { 'remove_supervisor_vrouter_override':
		path => "/etc/init/supervisor-vrouter.override",
		ensure => absent,
	    }->
            */
            exec { 'remove_supervisor_override':
                command => "rm -rf /etc/init/supervisor-vrouter.override",
                provider => shell,
                logoutput => $contrail_logoutput,
            }
        }
    }

    # Install interface rename package for centos.
    if (inline_template('<%= @operatingsystem.downcase %>') == 'centos') {
        Notify["vmware_physical_intf = ${vmware_physical_intf}"] ->
        contrail::lib::contrail_rename_interface { 'centos-rename-interface' :
        }
    }
    # for storage
    ## Same condition as compute/service.pp
    if ($nfs_server == 'xxx' and $host_control_ip == $compute_ip_list[0] ) {
        contain ::contrail::compute::create_nfs
        Notify["vmware_physical_intf = ${vmware_physical_intf}"] ->Class['::contrail::compute::create_nfs']->Nova_config['neutron/admin_auth_url']
    }

    if ($openstack_manage_amqp or $openstack_amqp_ip_list) {
        $nova_compute_rabbit_hosts = $openstack_rabbit_servers
    } elsif ($nova_rabbit_hosts){
        $nova_compute_rabbit_hosts = $nova_rabbit_hosts
    } else {
        $nova_compute_rabbit_hosts = $contrail_rabbit_servers
    }

    $nova_params = {
      'neutron/admin_auth_url'=> {   value => "http://${keystone_ip_to_use}:35357/v2.0/" },
      'neutron/admin_tenant_name' => { value => 'services', },
      'neutron/admin_username' => { value => 'neutron', },
      'neutron/admin_password'=>  {  value => "${keystone_admin_password}" },
      'neutron/url' =>  {  value => "http://${config_ip_to_use}:9696" },
      'neutron/url_timeout' =>  {  value => "300" },
      'keystone_authtoken/admin_password'=> { value => "${keystone_admin_password}" },
      'compute/compute_driver'=> { value => "libvirt.LibvirtDriver" },
      'DEFAULT/rabbit_hosts' => {value => "${nova_compute_rabbit_hosts}"},
      'DEFAULT/novncproxy_base_url' => { value => "http://${host_control_ip}:5999/vnc_auto.html" },
      'oslo_messaging_rabbit/heartbeat_timeout_threshold' => { value => '0'},
    }
    if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
      $nova_params['keystone_authtoken/password'] = { value =>"${keystone_admin_password}" }
    }

    if (!('openstack' in $host_roles)){
      nova_config { 'glance/api_servers': value => "http://${glance_management_address}:9292"}
    }
    create_resources(nova_config, $nova_params, {} )

    # Update modprobe.conf
    if inline_template('<%= @operatingsystem.downcase %>') == 'centos' {
        # Ensure modprobe.conf file is present with right content.
        $modprobe_conf_file = '/etc/modprobe.conf'
        Contrail::Lib::Augeas_conf_rm["compute_rm_rabbit_port"] ->
        contrail::lib::augeas_conf_set { 'alias':
                config_file => $modprobe_conf_file,
                settings_hash => {'alias' => 'bridge off',},
                lens_to_use => 'spacevars.lns',
        } ->
        Class['::contrail::compute::add_dev_tun_in_cgroup_device_acl']
    }

    if ($physical_dev != undef and $physical_dev != 'vhost0') {
        $update_dev_net_cmd = "/bin/bash -c \"python /etc/contrail/contrail_setup_utils/update_dev_net_config_files.py --vhost_ip ${vhost_ip} ${multinet_opt} --dev \'${physical_dev}\' --compute_dev \'${contrail_compute_dev}\' --netmask \'${contrail_netmask}\' --gateway \'${contrail_gway}\' --cidr \'${contrail_cidr}\' --host_non_mgmt_ip \'${host_non_mgmt_ip}\' --mac ${contrail_macaddr} && echo update-dev-net-config >> /etc/contrail/contrail_compute_exec.out\""

        class { '::contrail::compute::update_dev_net_config':
            update_dev_net_cmd => $update_dev_net_cmd
        } ->
        File['/etc/contrail/agent_param']
        contain ::contrail::compute::update_dev_net_config
    }
    if ! defined(File['/etc/contrail/vnc_api_lib.ini']) {
        File['/etc/contrail/agent_param'] ->
        file { '/etc/contrail/vnc_api_lib.ini' :
            ensure  => present,
            content => template("${module_name}/vnc_api_lib.ini.erb"),
        } ->
        Contrail_vrouter_agent_config['DEFAULT/xmpp_auth_enable']
    }

    if $contrail_agent_mode == 'tsn' {
      Contrail_vrouter_agent_config['VIRTUAL-HOST-INTERFACE/compute_node_address'] ->
      contrail_vrouter_agent_config { 'DEFAULT/agent_mode' : value => "tsn"; } ->
      Contrail_vrouter_nodemgr_config['DISCOVERY/server']
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
    notify {"vmware_physical_intf = ${vmware_physical_intf}":; } ->
    Nova_config['neutron/admin_auth_url'] ->

    # set rpc backend in neutron.conf
    contrail::lib::augeas_conf_rm { "compute_neutron_rpc_backend":
        key => 'rpc_backend',
        config_file => '/etc/neutron/neutron.conf',
        lens_to_use => 'properties.lns',
        match_value => 'neutron.openstack.common.rpc.impl_qpid',
    } ->
    #set rpc backend in nova.conf
    contrail::lib::augeas_conf_rm { "compute_nova_rpc_backend":
        key => 'rpc_backend',
        config_file => '/etc/nova/nova.conf',
        lens_to_use => 'properties.lns',
        match_value => 'nova.openstack.common.rpc.impl_qpid',
    } ->
    # Remove rabbit host and port from nova.conf
    contrail::lib::augeas_conf_rm { "compute_rm_rabbit_host":
        key => 'rabbit_host',
        config_file => '/etc/nova/nova.conf',
        lens_to_use => 'properties.lns',
    } ->
    contrail::lib::augeas_conf_rm { "compute_rm_rabbit_port":
        key => 'rabbit_port',
        config_file => '/etc/nova/nova.conf',
        lens_to_use => 'properties.lns',
    } ->
    Class['::contrail::compute::add_dev_tun_in_cgroup_device_acl'] ->

    file { '/etc/contrail/vrouter_nodemgr_param' :
        ensure  => present,
        require => Package['contrail-openstack-vrouter'],
        content => template("${module_name}/vrouter_nodemgr_param.erb"),
    } ->

    file { '/etc/contrail/agent_param' :
        ensure  => present,
        content => template("${module_name}/agent_param.tmpl.erb"),
    } ->


    notify { "sriov = ${sriov}":; }
    $sriov_keys = keys($sriov)
    if (!empty($sriov)) {
      contrail::lib::setup_sriov_wrapper {$sriov_keys:
            intf_hash => $sriov,
            enable_dpdk => $enable_dpdk,
      }
    }

    contrail_vrouter_agent_config {
      'DEFAULT/xmpp_auth_enable' : value => "$xmpp_auth_enable";
      'DEFAULT/xmpp_server_cert' : value => "/etc/contrail/ssl/certs/server.pem";
      'DEFAULT/xmpp_server_key' : value => "/etc/contrail/ssl/private/server-privkey.pem";
      'DEFAULT/xmpp_ca_cert' : value => "/etc/contrail/ssl/certs/ca-cert.pem";
      'DEFAULT/platform' : value => "$contrail_work_mode";
      'DEFAULT/physical_interface_address' : value => "$pci_address";
      'DEFAULT/physical_interface_mac' : value => "$contrail_macaddr";
      'DEFAULT/xmpp_dns_auth_enable' : value => "$xmpp_dns_auth_enable";
      'DISCOVERY/server' : value => "$discovery_ip";
      'DISCOVERY/max_control_nodes' : value => "$number_control_nodes";
      'HYPERVISOR/type' : value => "$hypervisor_type";
      'HYPERVISOR/vmware_physical_interface' : value => "$vmware_physical_intf";
      'NETWORKS/control_network_ip' : value => "$host_control_ip";
      'VIRTUAL-HOST-INTERFACE/name' : value => "vhost0";
      'VIRTUAL-HOST-INTERFACE/ip' : value => "$host_control_ip/$contrail_cidr";
      'VIRTUAL-HOST-INTERFACE/gateway' : value => "$contrail_gway";
      'VIRTUAL-HOST-INTERFACE/physical_interface' : value => "$contrail_dev";
      'SERVICE-INSTANCE/netns_command' : value => "/usr/bin/opencontrail-vrouter-netns";
    } ->
    contrail_vrouter_agent_config {
      'VIRTUAL-HOST-INTERFACE/compute_node_address' : ensure => 'absent';
    } ->

    contrail_vrouter_nodemgr_config {
      'DISCOVERY/server' : value => "$discovery_ip";
      'DISCOVERY/port' : value => '5998';
    } ->
    class {'::contrail::compute::add_vnc_config':
        host_control_ip => $host_control_ip,
        config_ip_to_use => $config_ip_to_use,
        keystone_admin_user => $keystone_admin_user,
        keystone_admin_password => $keystone_admin_password,
        keystone_admin_tenant => $keystone_admin_tenant,
        openstack_ip => $openstack_ip,
        enable_dpdk => $enable_dpdk
    }
    ->
    contrail::lib::setup_hugepages{ 'huge_pages':
    }
    ->
    contrail::lib::setup_coremask{ 'core_mask':
    }
    ->
    class {'::contrail::compute::setup_compute_server_setup':}
    ->
    reboot { 'compute':
      apply => "immediately",
      subscribe       => Exec ["setup-compute-server-setup"],
      timeout => 0,
    }
    contain ::contrail::compute::setup_compute_server_setup
    contain ::contrail::compute::add_vnc_config
    # Now reboot the system
    if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
        contain ::contrail::compute::cp_ifcfg_file
    }

    contain ::contrail::compute::add_dev_tun_in_cgroup_device_acl
    # Ensure ctrl-details file is present with right content.
    if ! defined(Class['::contrail::ctrl_details']) {
        Notify["vmware_physical_intf = ${vmware_physical_intf}"] ->
        Class['::contrail::ctrl_details'] ->
        Nova_config['neutron/admin_auth_url']
        contain ::contrail::ctrl_details
    }
    if ! defined(Class['::contrail::xmpp_cert_files']) {
        Notify["vmware_physical_intf = ${vmware_physical_intf}"] ->
        Class['::contrail::xmpp_cert_files'] ->
        Nova_config['neutron/admin_auth_url']
        contain ::contrail::xmpp_cert_files
    }

    if ! defined(File['/opt/contrail/bin/set_rabbit_tcp_params.py']) {
        Notify["vmware_physical_intf = ${vmware_physical_intf}"] ->
        Class['::contrail::compute::exec_set_rabbitmq_tcp_params'] ->
        Nova_config['neutron/admin_auth_url']
        contain ::contrail::compute::exec_set_rabbitmq_tcp_params
    }
}
