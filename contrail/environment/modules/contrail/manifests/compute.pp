# This class is used to configure software and services required
# to run compute module (vrouter and agent) of contrail software suit.
#
# === Parameters:
#
# [*host_control_ip*]
#     IP address of the server.
#     If server has separate interfaces for management and control, this
#     parameter should provide control interface IP address.
#
# [*config_ip*]
#     Control interface IP address of the server where config module of
#     contrail cluster is configured. If there are multiple config nodes,
#     specify address of first config node. Actual value used by this module
#     logic would be contrail_internal_vip or internal_vip, if those are 
#     specified for HA setup.
#
# [*openstack_ip*]
#     IP address of server running openstack services. If the server has
#     separate interfaces for management and control, this parameter
#     should provide control interface IP address.
#
# [*control_ip_list*]
#     List of IP addresses running contrail controller module. This is used
#     to derive number of control nodes (needed to be added to config file).
#
# [*compute_ip_list*]
#     List of IP addresses running contrail compute module. This is used
#     to decide is nfs is to be created, this is done on first node only.
#
# [*keystone_ip*]
#     IP address of server running keystone service. Should be specified if
#     keystone is running on a server other than openstack server.
#     (optional) - Defaults to "", meaning use openstack_ip.
#
# [*keystone_service_token*]
#     openstack service token value.
#     (optional) - Defaults to "c0ntrail123"
#
# [*keystone_auth_protocol*]
#     Keystone authentication protocol.
#     (optional) - Defaults to "http".
#
# [*keystone_auth_port*]
#     Keystone authentication port.
#     (optional) - Defaults to "35357".
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
# [*neutron_service_protocol*]
#     Neutron Service protocol.
#     (optional) - Defaults to "http".
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
# [*haproxy*]
#     whether haproxy is configured and enabled. If internal_vip or contrail_internal_vip
#     is specified, value of false is used by the logic in this module.
#     (optional) - Defaults to false. 
#
# [*host_non_mgmt_ip*]
#     Specify address of data/control interface, only if there are separate interfaces
#     for management and data/control. If system has single interface for both, leave
#     default value of "".
#     (optional) - Defaults to "".
#
# [*host_non_mgmt_gateway*]
#     Gateway IP address of the data interface of the server. If server has separate
#     interfaces for management and control/data, this parameter should provide gateway
#     ip address of data interface.
#     (optional) - Defaults to "".
#
# [*metadata_secret*]
#     metadata secret value from openstack node.
#     (optional) - Defaults to "". 
#
# [*quantum_port*]
#     Quantum port number
#     (optional) - Defaults to "9697"
#
# [*quantum_service_protocol*]
#     Quantum Service protocol value (http or https)
#     (optional) - Defaults to "http".
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
#     (optional) - Defaults to ""
#
# [*vmware_ip*]
#     VM IP address (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*vmware_username*]
#     VM er name (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*vmware_password*]
#     VM password (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*vswitch*]
#     vswitch value (for ESXi/VMware host)
#     (optional) - Defaults to ""
#
# [*vgw_public_subnet*]
#     Public subnet value for virtual gateway configuration.
#     (optional) - Defaults to ""
#
# [*vgw_public_vn_name*]
#     Public virtual network name value for virtual gateway configuration.
#     (optional) - Defaults to ""
#
# [*vgw_interface*]
#     Interface name for virtual gateway configuration.
#     (optional) - Defaults to ""
#
# [*vgw_gateway_routes*]
#     Gateway routes for virtual gateway configuration.
#     (optional) - Defaults to ""
#
# [*nfs_server*]
#     nfs server address for storage
#     (optional) - Defaults to ""
#
# [*orchestrator*]
#     orchestrator being used for launching VMs.
#     (optional) - Defaults to "openstack"
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::compute (
    $host_control_ip = $::contrail::params::host_ip,
    $config_ip = $::contrail::params::config_ip_list[0],
    $openstack_ip = $::contrail::params::openstack_ip_list[0],
    $control_ip_list = $::contrail::params::control_ip_list,
    $compute_ip_list = $::contrail::params::compute_ip_list,
    $keystone_ip = $::contrail::params::keystone_ip,
    $keystone_service_token = $::contrail::params::keystone_service_token,
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
) inherits ::contrail::params {

    $contrail_num_controls = inline_template("<%= @control_ip_list.length %>")

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

    # Set config IP to be used.
    if ($contrail_internal_vip != "") {
        $config_ip_to_use = $contrail_internal_vip
    }
    elsif ($internal_vip != "") {
        $config_ip_to_use = $internal_vip
    }
    else {
        $config_ip_to_use = $config_ip
    }

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

    # set number of control nodes.
    $number_control_nodes = size($control_ip_list)
    # Set vhost_ip and multi_net flag
    if ($host_non_mgmt_ip != "") {
        $multinet = true
        $multinet_opt = "--multi_net"
        $vhost_ip = $host_non_mgmt_ip
    }
    else {
        $multinet = false
        $multinet_opt = ""
        $vhost_ip = $host_control_ip
    }
    $physical_dev = get_device_name("$vhost_ip")
    if ($physical_dev != "vhost0") {
        $contrail_dev = $physical_dev
    } else {
        $contrail_dev_mac = inline_template("<%= scope.lookupvar('macaddress_' + @physical_dev) %>")
        $contrail_dev = get_device_name_by_mac("$contrail_dev_mac") 
    }
    if ($multinet) {
        $contrail_compute_dev = get_device_name("$host_control_ip")
    }
    else {
        $contrail_compute_dev = ""
    }

    if ($physical_dev == undef) {
	fail("contrail device is not found")
    }

    # Get Mac, netmask and gway
    $contrail_macaddr = inline_template("<%= scope.lookupvar('macaddress_' + @physical_dev) %>")
    $contrail_netmask = inline_template("<%= scope.lookupvar('netmask_' + @physical_dev) %>")
    $contrail_cidr = convert_netmask_to_cidr($contrail_netmask)
    if ($multinet == true) {
        $contrail_gway = $host_non_mgmt_gateway
    }
    else {
        $contrail_gway = $contrail_gateway
    }
    if ($haproxy == true) {
        $quantum_ip = "127.0.0.1"
        $discovery_ip = "127.0.0.1"
    } else {
        $quantum_ip = $config_ip_to_use
        $discovery_ip = $config_ip_to_use
    }

    if ( $vmware_ip != "" ) {
	$hypervisor_type = "vmware"
	$vmware_physical_intf = "eth1"
    } else {
	$hypervisor_type = "kvm"
	$vmware_physical_intf = "eth1"
    }

    if 'tsn' in $contrail_host_roles {
        $contrail_agent_mode = 'tsn'
    } else {
        $contrail_agent_mode = ""
    }
    # Debug Print all variable values
    notify {"host_control_ip = $host_control_ip":; } ->
    notify {"config_ip = $config_ip":; } ->
    notify {"openstack_ip = $openstack_ip":; } ->
    notify {"control_ip_list = $control_ip_list":; } ->
    notify {"compute_ip_list = $compute_ip_list":; } ->
    notify {"keystone_service_token = $keystone_service_token":; } ->
    notify {"keystone_ip = $keystone_ip":; } ->
    notify {"keystone_auth_protocol = $keystone_auth_protocol":; } ->
    notify {"keystone_auth_port = $keystone_auth_port":; } ->
    notify {"openstack_manage_amqp = $openstack_manage_amqp":; } ->
    notify {"amqp_server_ip = $amqp_server_ip":; } ->
    notify {"openstack_mgmt_ip = $openstack_mgmt_ip":; } ->
    notify {"amqp_server_ip_to_use = $amqp_server_ip_to_use":; } ->
    notify {"neutron_service_protocol = $neutron_service_protocol":; } ->
    notify {"keystone_admin_user = $keystone_admin_user":; } ->
    notify {"keystone_admin_password = $keystone_admin_password":; } ->
    notify {"keystone_admin_tenant = $keystone_admin_tenant":; } ->
    notify {"haproxy = $haproxy":; } ->
    notify {"host_non_mgmt_ip = $host_non_mgmt_ip":; } ->
    notify {"host_non_mgmt_gateway = $host_non_mgmt_gateway":; } ->
    notify {"metadata_secret = $metadata_secret":; } ->
    notify {"internal_vip = $internal_vip":; } ->
    notify {"external_vip = $external_vip":; } ->
    notify {"contrail_internal_vip = $contrail_internal_vip":; } ->
    notify {"vmware_ip = $vmware_ip":; } ->
    notify {"vmware_username = $vmware_username":; } ->
    notify {"vmware_password = $vmware_password":; } ->
    notify {"vmware_vswitch = $vmware_vswitch":; } ->
    notify {"vgw_public_subnet = $vgw_public_subnet":; } ->
    notify {"vgw_public_vn_name = $vgw_public_vn_name":; } ->
    notify {"vgw_interface = $vgw_interface":; } ->
    notify {"vgw_gateway_routes = $vgw_gateway_routes":; } ->
    notify {"nfs_server = $nfs_server":; } ->
    notify {"keystone_ip_to_use = $keystone_ip_to_use":; } ->
    notify {"config_ip_to_use = $config_ip_to_use":; } ->
    notify {"number_control_nodes = $number_control_nodes":; } ->
    notify {"multinet = $multinet":; } ->
    notify {"multinet_opt = $multinet_opt":; } ->
    notify {"vhost_ip = $vhost_ip":; } ->
    notify {"physical_dev = $physical_dev":; } ->
    notify {"contrail_compute_dev = $contrail_compute_dev":; } ->
    notify {"contrail_macaddr = $contrail_macaddr":; } ->
    notify {"contrail_netmask = $contrail_netmask":; } ->
    notify {"contrail_cidr = $contrail_cidr":; } ->
    notify {"contrail_gway = $contrail_gway":; } ->
    notify {"contrail_gateway = $contrail_gateway":; } ->
    notify {"quantum_port = $quantum_port":; } ->
    notify {"quantum_ip = $quantum_ip":; } ->
    notify {"quantum_service_protocol = $quantum_service_protocol":; } ->
    notify {"discovery_ip = $discovery_ip":; } ->
    notify {"hypervisor_type = $hypervisor_type":; } ->
    notify {"vmware_physical_intf = $vmware_physical_intf":; }

    #Determine vrouter package to be installed based on the kernel
    #TODO add DPDK support here


    if ($operatingsystem == "Ubuntu"){

        if ($lsbdistrelease == "14.04") {
            if ($kernelrelease == "3.13.0-40-generic") {
            	$vrouter_pkg = "contrail-vrouter-3.13.0-40-generic" 
            } else {
            	$vrouter_pkg = "contrail-vrouter-dkms" 
            }
        } elsif ($lsbdistrelease == "12.04") {
            if ($kernelrelease == "3.13.0-34-generic") {
            	$vrouter_pkg = "contrail-vrouter-3.13.0-34-generic" 
            } else {
            	$vrouter_pkg = "contrail-vrouter-dkms" 
            }
        }
    }
    else {
      	$vrouter_pkg = "contrail-vrouter" 
    }


    contrail::lib::report_status { "compute_started":
        state => "compute_started", 
        contrail_logoutput => $contrail_logoutput }
    ->
    # Main code for class starts here
    # Ensure all needed packages are latest
    package { $vrouter_pkg : ensure => latest,}->
    package { 'contrail-openstack-vrouter' : ensure => latest,}

    if ($enable_lbass == true) {
        package{'haproxy': ensure => present,} ->
        package{'iproute': ensure => present,}

    }

    #The below way should be the ideal one,
    #But when vrouter-agent starts , the actual physical interface is not removed,
    #when vhost comes up.
    #This results in non-reachablity
    #package { 'contrail-openstack-vrouter' : ensure => latest, notify => "Service[supervisor-vrouter]"}

    if ($operatingsystem == "Ubuntu"){
	file {"/etc/init/supervisor-vrouter.override": ensure => absent, require => Package['contrail-openstack-vrouter']}
    }

    # Install interface rename package for centos.
    if (inline_template('<%= @operatingsystem.downcase %>') == "centos") {
        contrail::lib::contrail-rename-interface { "centos-rename-interface" :
            require => Package["contrail-openstack-vrouter"]
        }
    }

    # for storage
    if ($nfs_server == "xxx" and $host_control_ip == $compute_ip_list[0] ) {
        exec { "create-nfs" :
            command => "mkdir -p /var/tmp/glance-images/ && chmod 777 /var/tmp/glance-images/ && echo \"/var/tmp/glance-images *(rw,sync,no_subtree_check)\" >> /etc/exports && sudo /etc/init.d/nfs-kernel-server restart && echo create-nfs >> /etc/contrail/contrail_compute_exec.out ",
            require => [  ],
            unless  => "grep -qx create-nfs  /etc/contrail/contrail_compute_exec.out",
            provider => shell,
            logoutput => $contrail_logoutput
        }
    }

    # Set Neutron Admin auth URL (should be done only for ubuntu)
    exec { "exec-compute-neutron-admin" :
	command => "echo \"neutron_admin_auth_url = http://$keystone_ip_to_use:5000/v2.0\" >> /etc/nova/nova.conf && echo exec-compute-neutron-admin >> /etc/contrail/contrail_compute_exec.out",
	unless  => ["grep -qx exec-compute-neutron-admin /etc/contrail/contrail_compute_exec.out",
		    "grep -qx \"neutron_admin_auth_url = http://$keystone_ip_to_use:5000/v2.0\" /etc/nova/nova.conf"],
	require => [ Package["contrail-openstack-vrouter"] ],
	provider => shell,
	logoutput => $contrail_logoutput
    } ->

    # set rpc backend in nova.conf
    exec { "exec-compute-update-nova-conf" :
        command => "sed -i \"s/^rpc_backend = nova.openstack.common.rpc.impl_qpid/#rpc_backend = nova.openstack.common.rpc.impl_qpid/g\" /etc/nova/nova.conf && echo exec-update-nova-conf >> /etc/contrail/contrail_common_exec.out",
        unless  => ["[ ! -f /etc/nova/nova.conf ]",
		    "grep -qx exec-update-nova-conf /etc/contrail/contrail_common_exec.out"],
	require => [ Package["contrail-openstack-vrouter"] ],
        provider => shell,
        logoutput => $contrail_logoutput
    }

    if ! defined(Exec["neutron-conf-exec"]) {
	exec { "neutron-conf-exec":
	    command => "sudo sed -i 's/rpc_backend\s*=\s*neutron.openstack.common.rpc.impl_qpid/#rpc_backend = neutron.openstack.common.rpc.impl_qpid/g' /etc/neutron/neutron.conf && echo neutron-conf-exec >> /etc/contrail/contrail_openstack_exec.out",
	    onlyif => "test -f /etc/neutron/neutron.conf",
	    unless  => "grep -qx neutron-conf-exec /etc/contrail/contrail_openstack_exec.out",
	    require => [ Package["contrail-openstack-vrouter"] ],
	    provider => shell,
	    logoutput => $contrail_logoutput
	}
    }

    if ! defined(Exec["quantum-conf-exec"]) {
	exec { "quantum-conf-exec":
	    command => "sudo sed -i 's/rpc_backend\s*=\s*quantum.openstack.common.rpc.impl_qpid/#rpc_backend = quantum.openstack.common.rpc.impl_qpid/g' /etc/quantum/quantum.conf && echo quantum-conf-exec >> /etc/contrail/contrail_openstack_exec.out",
	    onlyif => "test -f /etc/quantum/quantum.conf",
	    unless  => "grep -qx quantum-conf-exec /etc/contrail/contrail_openstack_exec.out",
	    require => [ Package["contrail-openstack-vrouter"] ],
	    provider => shell,
	    logoutput => $contrail_logoutput
	}
    }

    # Update modprobe.conf
    if inline_template('<%= @operatingsystem.downcase %>') == "centos" {
	file { "/etc/modprobe.conf" :
	    ensure  => present,
	    require => Package['contrail-openstack-vrouter'],
	    content => template("$module_name/modprobe.conf.erb")
	}
    }

    file { "/etc/contrail/contrail_setup_utils/add_dev_tun_in_cgroup_device_acl.sh":
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
        source => "puppet:///modules/$module_name/add_dev_tun_in_cgroup_device_acl.sh"
    }

    exec { "add_dev_tun_in_cgroup_device_acl" :
        command => "./add_dev_tun_in_cgroup_device_acl.sh && echo add_dev_tun_in_cgroup_device_acl >> /etc/contrail/contrail_compute_exec.out",
	cwd => "/etc/contrail/contrail_setup_utils/",
        require => [ File["/etc/contrail/contrail_setup_utils/add_dev_tun_in_cgroup_device_acl.sh"] ,Package['contrail-openstack-vrouter'] ],
        unless  => "grep -qx add_dev_tun_in_cgroup_device_acl /etc/contrail/contrail_compute_exec.out",
        provider => shell,
        logoutput => $contrail_logoutput
    }

    file { "/etc/contrail/vrouter_nodemgr_param" :
	ensure  => present,
	require => Package["contrail-openstack-vrouter"],
	content => template("$module_name/vrouter_nodemgr_param.erb"),
    }

    # Ensure ctrl-details file is present with right content.
    if ! defined(File["/etc/contrail/ctrl-details"]) {
	file { "/etc/contrail/ctrl-details" :
	    ensure  => present,
	    content => template("$module_name/ctrl-details.erb"),
	}
    }


    if ! defined(File["/opt/contrail/bin/set_rabbit_tcp_params.py"]) {

	# check_wsrep
	file { "/opt/contrail/bin/set_rabbit_tcp_params.py" :
	    ensure  => present,
	    mode => 0755,
	    group => root,
	    source => "puppet:///modules/$module_name/set_rabbit_tcp_params.py"
	}


	exec { "exec_set_rabbitmq_tcp_params" :
	    command => "python /opt/contrail/bin/set_rabbit_tcp_params.py && echo exec_set_rabbitmq_tcp_params >> /etc/contrail/contrail_openstack_exec.out",
	    cwd => "/opt/contrail/bin/",
	    unless  => "grep -qx exec_set_rabbitmq_tcp_params /etc/contrail/contrail_openstack_exec.out",
	    provider => shell,
	    require => [ File["/opt/contrail/bin/set_rabbit_tcp_params.py"] ],
	    logoutput => $contrail_logoutput
	}
    }

    # Ensure service.token file is present with right content.
    if ! defined(File["/etc/contrail/service.token"]) {
	file { "/etc/contrail/service.token" :
	    ensure  => present,
	    content => template("$module_name/service.token.erb"),
	}
    }

    if ($physical_dev != undef and $physical_dev != "vhost0") {
	file { "/etc/contrail/contrail_setup_utils/update_dev_net_config_files.py":
	    ensure  => present,
	    mode => 0755,
	    owner => root,
	    group => root,
	    source => "puppet:///modules/$module_name/update_dev_net_config_files.py"
	}
        $update_dev_net_cmd = "/bin/bash -c \"python /etc/contrail/contrail_setup_utils/update_dev_net_config_files.py --vhost_ip $vhost_ip $multinet_opt --dev \'$physical_dev\' --compute_dev \'$contrail_compute_dev\' --netmask \'$contrail_netmask\' --gateway \'$contrail_gway\' --cidr \'$contrail_cidr\' --host_non_mgmt_ip \'$host_non_mgmt_ip\' --mac $contrail_macaddr && echo update-dev-net-config >> /etc/contrail/contrail_compute_exec.out\""

	notify { "Update dev net config is $update_dev_net_cmd":; }

	exec { "update-dev-net-config" :
	    command => $update_dev_net_cmd,
	    require => [ File["/etc/contrail/contrail_setup_utils/update_dev_net_config_files.py"] ],
	    unless  => "grep -qx update-dev-net-config /etc/contrail/contrail_compute_exec.out",
	    provider => shell,
	    logoutput => $contrail_logoutput
	} 

    } else {
        #Not needed for now, as compute upgrade anyways goes for a reboot,
        #On 14.04, since network restart is not supported,
        #We need to stop vrouter, modprobe -r vrouter and start vrouter again.
        #
        /*
	exec { "service_network_restart" :
	    command => "/etc/init.d/networking restart && echo service_network_restart >> /etc/contrail/contrail_compute_exec.out",
	    require => Package["contrail-openstack-vrouter"],
	    unless  => "grep -qx service_network_restart /etc/contrail/contrail_compute_exec.out",
	    provider => shell,
	    logoutput => $contrail_logoutput
	}
        ->
        */
    }

    file { "/etc/contrail/default_pmac" :
	ensure  => present,
	require => Package["contrail-openstack-vrouter"],
	content => template("$module_name/default_pmac.erb"),
    } ->
    file { "/etc/contrail/agent_param" :
	ensure  => present,
	require => Package["contrail-openstack-vrouter"],
	content => template("$module_name/agent_param.tmpl.erb"),
    }
    if ! defined(File["/etc/contrail/vnc_api_lib.ini"]) {
	file { "/etc/contrail/vnc_api_lib.ini" :
	    ensure  => present,
	    require => Package["contrail-openstack-vrouter"],
	    content => template("$module_name/vnc_api_lib.ini.erb"),
	}
    }
    file { "/etc/contrail/contrail-vrouter-agent.conf" :
	ensure  => present,
	require => Package["contrail-openstack-vrouter"],
	content => template("$module_name/contrail-vrouter-agent.conf.erb"),
    } ->
    file { "/etc/contrail/contrail-vrouter-nodemgr.conf" :
        ensure  => present,
        require => Package["contrail-openstack-vrouter"],
        content => template("$module_name/contrail-vrouter-nodemgr.conf.erb"),
    } ->


    file { "/opt/contrail/utils/provision_vrouter.py":
	ensure  => present,
	mode => 0755,
	owner => root,
	group => root
    }
    exec { "add-vnc-config" :
	command => "/bin/bash -c \"python /opt/contrail/utils/provision_vrouter.py --host_name $::hostname --host_ip $host_control_ip --api_server_ip $config_ip_to_use --oper add --admin_user $keystone_admin_user --admin_password $keystone_admin_password --admin_tenant_name $keystone_admin_tenant --openstack_ip $openstack_ip && echo add-vnc-config >> /etc/contrail/contrail_compute_exec.out\"",
	require => File["/opt/contrail/utils/provision_vrouter.py"],
	unless  => "grep -qx add-vnc-config /etc/contrail/contrail_compute_exec.out",
	provider => shell,
	logoutput => $contrail_logoutput
    } ->

    file { "/opt/contrail/bin/compute-server-setup.sh":
	ensure  => present,
	mode => 0755,
	owner => root,
	group => root,
	require => File["/etc/contrail/ctrl-details"],
    } ->
    exec { "setup-compute-server-setup" :
	command => "/opt/contrail/bin/compute-server-setup.sh; echo setup-compute-server-setup >> /etc/contrail/contrail_compute_exec.out",
	require => File["/opt/contrail/bin/compute-server-setup.sh"],
	unless  => "grep -qx setup-compute-server-setup /etc/contrail/contrail_compute_exec.out",
	provider => shell,
	logoutput => $contrail_logoutput
    } ->
    exec { "fix-neutron-tenant-name" :
	command => "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_tenant_name services && echo fix-neutron-tenant-name >> /etc/contrail/contrail_compute_exec.out",
	unless  => "grep -qx fix-neutron-tenant-name /etc/contrail/contrail_compute_exec.out",
	provider => shell,
	logoutput => $contrail_logoutput

    } ->
    exec { "fix-neutron-admin-password" :
	command => "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_password $keystone_admin_password && echo fix-neutron-admin-password >> /etc/contrail/contrail_compute_exec.out",
	unless  => "grep -qx fix-neutron-admin-password /etc/contrail/contrail_compute_exec.out",
	provider => shell,
	logoutput => $contrail_logoutput

    } ->
    exec { "fix-keystone-admin-password" :
	command => "openstack-config --set /etc/nova/nova.conf keystone_authtoken admin_password $keystone_admin_password && echo fix-keystone-admin-password >> /etc/contrail/contrail_compute_exec.out",
	unless  => "grep -qx fix-keystone-admin-password /etc/contrail/contrail_compute_exec.out",
	provider => shell,
	logoutput => $contrail_logoutput

    } ->
        contrail::lib::report_status { "compute_completed":
            state => "compute_completed", 
            contrail_logoutput => $contrail_logoutput } ->
    exec { "flag-reboot-server" :
	command   => "echo flag-reboot-server >> /etc/contrail/contrail_compute_exec.out",
	unless => ["grep -qx flag-reboot-server /etc/contrail/contrail_compute_exec.out"],
	provider => "shell",
	logoutput => $contrail_logoutput
    }
    #1449971
    /*
    -> 
    service { "supervisor-vrouter" :
	enable => true,
	require => [ Package['contrail-openstack-vrouter']
		 ],
	ensure => running,
    }
    */
    ->
    service { "nova-compute" :
	enable => true,
	require => [ Package['contrail-openstack-vrouter']
		 ],
	ensure => running,
    }

    # Now reboot the system
    if ($operatingsystem == "Centos" or $operatingsystem == "Fedora") {
	exec { "cp-ifcfg-file" :
	    command   => "cp -f /etc/contrail/ifcfg-* /etc/sysconfig/network-scripts && echo cp-ifcfg-file >> /etc/contrail/contrail_compute_exec.out",
	    before => Exec["reboot-server"],
	    unless  => "grep -qx cp-ifcfg-file /etc/contrail/contrail_compute_exec.out",
	    provider => "shell",
	    require => Exec["flag-reboot-server"],
	    logoutput => $contrail_logoutput
	}
    }
}
