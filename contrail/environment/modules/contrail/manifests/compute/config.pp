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
  $neutron_password = $::contrail::params::os_neutron_password,
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
  $neutron_ip_to_use = $::contrail::params::neutron_ip_to_use,
  $rabbit_use_ssl     = $::contrail::params::contrail_amqp_ssl,
  $kombu_ssl_ca_certs = $::contrail::params::kombu_ssl_ca_certs,
  $kombu_ssl_certfile = $::contrail::params::kombu_ssl_certfile,
  $kombu_ssl_keyfile  = $::contrail::params::kombu_ssl_keyfile,
  $upgrade_needed = $::contrail::params::upgrade_needed,
  $qos = $::contrail::params::qos,
  $core_mask= $::contrail::params::core_mask,
  $vncproxy_url = $::contrail::params::vncproxy_base_url
){
  $config_ip_to_use = $::contrail::params::config_ip_to_use
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use
  $openstack_ip_to_use = $::contrail::params::openstack_ip_to_use
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

  $quantum_ip = $config_ip_to_use
  $discovery_ip = $config_ip_to_use

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
      exec { 'remove_supervisor_override':
        command => "rm -rf /etc/init/supervisor-vrouter.override",
        provider => shell,
        logoutput => $contrail_logoutput,
      }
    }
  }

  # for storage
  ## Same condition as compute/service.pp
  if ($nfs_server == 'xxx' and $host_control_ip == $compute_ip_list[0] ) {
    contain ::contrail::compute::create_nfs

    Notify["vmware_physical_intf = ${vmware_physical_intf}"]
    -> Class['::contrail::compute::create_nfs']
    -> Nova_config['neutron/admin_auth_url']
  }

  $nova_compute_rabbit_hosts = pick($nova_rabbit_hosts,
                                    $openstack_rabbit_servers,
                                    $contrail_rabbit_servers)

  $nova_params = {
    'neutron/admin_auth_url'    => { value => "http://${keystone_ip_to_use}:35357/v2.0/" },
    'neutron/admin_tenant_name' => { value => 'services', },
    'neutron/project_name'      => { value => 'services', },
    'neutron/admin_username'    => { value => 'neutron', },
    'neutron/auth_strategy'     => { value => 'keystone', },
    'neutron/auth_type'         => { value => 'password', },
    'neutron/admin_password'    => { value => "${keystone_admin_password}" },
    'neutron/url'               => { value => "http://${neutron_ip_to_use}:9696" },
    'neutron/url_timeout'       => { value => "300" },
    'neutron/password'          => { value => "${neutron_password}" },
    'compute/compute_driver'    => { value => "libvirt.LibvirtDriver" },
    'DEFAULT/rabbit_hosts'      => { value => "${nova_compute_rabbit_hosts}"},
    'keystone_authtoken/admin_password' => { value => "${keystone_admin_password}" },
    'DEFAULT/novncproxy_base_url' => { value => "${vncproxy_url}" },
    'oslo_messaging_rabbit/heartbeat_timeout_threshold' => { value => '0'},
  }

  if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
    $nova_params['keystone_authtoken/password'] = { value =>"${keystone_admin_password}" }
  }

  if ($core_mask != '') {
    $nova_params['DEFAULT/vcpu_pin_set'] = { value => build_vcpu_pin_list($core_mask) }
  }

  if ($rabbit_use_ssl) {
    contrail::lib::rabbitmq_ssl{'compute_rabbitmq':rabbit_use_ssl => $rabbit_use_ssl}

    $nova_params['oslo_messaging_rabbit/kombu_ssl_ca_certs'] = {value => $kombu_ssl_ca_certs }
    $nova_params['oslo_messaging_rabbit/rabbit_use_ssl']     = {value => $rabbit_use_ssl}
    $nova_params['oslo_messaging_rabbit/kombu_ssl_certfile'] = {value => $kombu_ssl_certfile}
    $nova_params['oslo_messaging_rabbit/kombu_ssl_keyfile']  = {value => $kombu_ssl_keyfile}
    $nova_params['oslo_messaging_rabbit/kombu_ssl_version']  = {value => 'TLSv1'}
  }

  if (!('openstack' in $host_roles)){
    nova_config { 'glance/api_servers':
      value => "http://${openstack_ip_to_use}:9292"}
  }
  create_resources(nova_config, $nova_params, {} )

  # Update modprobe.conf
  if inline_template('<%= @operatingsystem.downcase %>') == 'centos' {
    # Ensure modprobe.conf file is present with right content.
    $modprobe_conf_file = '/etc/modprobe.conf'
    contrail::lib::augeas_conf_set { 'alias':
              config_file => $modprobe_conf_file,
              settings_hash => {'alias' => 'bridge off',},
              lens_to_use => 'spacevars.lns',
    } ->
    Class['::contrail::compute::add_dev_tun_in_cgroup_device_acl']
  }

  if ($physical_dev != undef and $physical_dev != 'vhost0') {
    $update_dev_net_cmd = "/bin/bash -c \
        \"python /etc/contrail/contrail_setup_utils/update_dev_net_config_files.py \
        --vhost_ip ${vhost_ip} \
        ${multinet_opt} \
        --dev \'${physical_dev}\' \
        --compute_dev \'${contrail_compute_dev}\' \
        --netmask \'${contrail_netmask}\' \
        --gateway \'${contrail_gway}\' \
        --cidr \'${contrail_cidr}\' \
        --host_non_mgmt_ip \'${host_non_mgmt_ip}\' \
        --mac ${contrail_macaddr} \
        && echo update-dev-net-config >> /etc/contrail/contrail_compute_exec.out\""

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

  notify {"vmware_physical_intf = ${vmware_physical_intf}":; } ->

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

  notify {"qos = ${qos}":;}
  $qos_queue_ids = keys($qos)
  if (!empty($qos)) {
    contrail::lib::setup_qos {$qos_queue_ids:
      qos_hash => $qos,
    }
  }

  if ! defined(Class['::contrail::xmpp_cert_files']) {
    if ($upgrade_needed != 1) {
      Notify["vmware_physical_intf = ${vmware_physical_intf}"] ->
      Class['::contrail::xmpp_cert_files'] ->
      Reboot['compute']
    } else {
      Notify["vmware_physical_intf = ${vmware_physical_intf}"] ->		
      Class['::contrail::xmpp_cert_files'] ->		
      Nova_config['neutron/admin_auth_url']		
    }

    contain ::contrail::xmpp_cert_files
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
  if ($upgrade_needed != 1) {
      Class ['::contrail::compute::setup_compute_server_setup'] ->
      reboot { 'compute':
        apply => "immediately",
        subscribe       => Exec ["setup-compute-server-setup"],
        timeout => 0,
      }
  }

  Class['::contrail::compute::setup_compute_server_setup'] -> Nova_config <||>

  contain ::contrail::compute::add_vnc_config
  # Now reboot the system
  if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
    Class['::contrail::compute::setup_compute_server_setup'] ->
     Class['::contrail::compute::cp_ifcfg_file'] ->
     # remove blank password line from nova.conf
     exec { "set-nova-password":
       command => "sed -i \'s/^password=$/password=${keystone_admin_password}/\' /etc/nova/nova.conf && echo exec-set-nova-password >> /etc/contrail/exec-contrail-compute.out",
       provider => shell,
       unless => "grep -qx set-nova-conf /etc/contrail/exec-contrail-compute.out",
       logoutput => true
    } ->
    Reboot['compute']
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

  sysctl::value {
    'net.ipv4.tcp_keepalive_time':    value => "5";
    'net.ipv4.tcp_keepalive_probes':  value => "5";
    'net.ipv4.tcp_keepalive_intvl':   value => "1";
  }
}
