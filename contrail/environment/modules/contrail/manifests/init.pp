# TODO: Document the class
# Class that gathers and provides all the paramater values to other
# modules. This class specifies default values for all the optional
# parameters. User specified values come from hiera data files create
# and specified.
#
# === Parameters:
#
# [*host_ip*]
#     Control interface IP address of the server.
#
# [*uuid*]
#     uuid number for the server.
#
# [*config_ip_list*]
#     List of control interface IP addresses of all the servers in cluster
#     configured to run contrail config node.
#
# [*control_ip_list*]
#     List of control interface IP addresses of all the servers in cluster
#     configured to run contrail control node.
#
# [*database_ip_list*]
#     List of control interface IP addresses of all the servers in cluster
#     configured to run contrail database node.
#
# [*collector_ip_list*]
#     List of control interface IP addresses of all the servers in cluster
#     configured to run contrail collector node.
#
# [*webui_ip_list*]
#     List of control interface IP addresses of all the servers in cluster
#     configured to run contrail webui node.
#
# [*openstack_ip_list*]
#     List of control interface IP addresses of all the servers in cluster
#     configured to run contrail openstack node.
#
# [*config_name_list*]
#     List of host names of all the servers in cluster configured to run
#     contrail config node.
#
# [*compute_name_list*]
#     List of host names of all the servers in cluster configured to run
#     contrail compute node.
#
# [*control_name_list*]
#     List of host names of all the servers in cluster configured to run
#     contrail control node.
#
# [*database_name_list*]
#     List of host names of all the servers in cluster configured to run
#     contrail database node.
#
# [*collector_name_list*]
#     List of host names of all the servers in cluster configured to run
#     contrail collector node.
#
# [*openstack_name_list*]
#     List of host names of all the servers in cluster configured to run
#     contrail openatack node.
#
# [*internal_vip*]
#     Virtual IP address to be used for openstack HA functionality on
#     control/data interface.  UI parameter.
#     (optional) - Defaults to "" (No openstack HA configured).
#
# [*external_vip*]
#     Virtual IP address to be used for openstack HA functionality on
#     management interface.  UI parameter.
#     (optional) - Defaults to "" (No openstack mgmt HA configured).
#
# [*contrail_internal_vip*]
#     Virtual IP address to be used for contrail HA functionality on
#     control/data interface.
#     This parameter is to be specified only if contrail HA IP address is
#     different from openstack HA. UI parameter.
#     (optional) - Defaults to "" (Follow internal_vip setting for contrail
#                  HA functionality).
#
# [*contrail_external_vip*]
#     Virtual IP address to be used for openstack HA functionality on
#     management interface.  UI parameter.
#     (optional) - Defaults to "" (No contrail mgmt HA configured).
#
# [*internal_virtual_router_id*]
#     Virtual router ID for the Openstack HA nodes in control/data (internal)
#     network.  UI parameter.
#     (optional) - Defaults to 102(No openstack HA configured).
#
# [*external_virtual_router_id*]
#     Virtual router ID for the Openstack HA nodes in management(external)
#     network.  UI parameter.
#     (optional) - Defaults to 101(No openstack HA configured).
#
# [*contrail_internal_virtual_router_id*]
#     Virtual router ID for the Contrail HA nodes in control/data (internal)
#     network.  UI parameter.
#     (optional) - Defaults to 103(No contrail mgmt HA configured).
#
# [*contrail_external_virtual_router_id*]
#     Virtual router ID for the Contrail HA nodes in managment(external)
#     network.  UI parameter.
#     (optional) - Defaults to 104(No contrail mgmt HA configured).
#
# [*database_ip_port*]
#     IP port number used by database service.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "9160".
#
# [*analytics_data_ttl*]
#     Time to live (TTL) for analytics data in number of hours.
#     (optional) - Defaults to "48". UI parameter.
#
# [*analytics_config_audit_ttl*]
#     TTL for config audit data in hours.
#     (optional) - Defaults to 2160 hours. UI parameter.
#
# [*analytics_statistics_ttl*]
#     TTL for statistics data in hours.
#     (optional) - Defaults to 168 hours. UI parameter.
#
# [*analytics_flow_ttl*]
#     TTL for flow data in hours.
#     (optional) - Defaults to 2 hours. UI parameter.
#
# [*snmp_scan_frequency*]
#     SNMP full scan frequency (in seconds).
#     (optional) - Defaults to 600 seconds. UI parameter.
#
# [*snmp_fast_scan_frequency*]
#     SNMP fast scan frequency (in seconds).
#     (optional) - Defaults to 60 seconds. UI parameter.
#
# [*topology_scan_frequency*]
#     Topology scan frequency (in seconds).
#     (optional) - Defaults to 60 seconds. UI parameter.
#
# [*analytics_syslog_port*]
#     Syslog port number used by analytics.
#     (optional) - Defaults to "-1". UI parameter.
#
# [*use_certs*]
#     flag to indicate if certs to be used in authenticating service access.
#     Leave the value at default.
#     (optional) - Defaults to false.
#
# [*puppet_server*]
#     If puppet server is used to fetch/store certificates.
#     Leave the value at default.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "" (puppet CA not used).
#
# [*database_initial_token*]
#     Database initial token value used for cassandra configuration.
#     Leave the value at default.
#     (optional) - Defaults to 0.
#
# [*database_dir*]
#     Directory used for cassandra database files.
#     Leave the value at default.
#     (optional) - Defaults to "/var/lib/cassandra". UI parameter.
#
# [*analytics_data_dir*]
#     Directory used for analytics data files.
#     (optional) - Defaults to "" (use database_dir). UI parameter.
#
# [*ssd_data_dir*]
#     Directory used for ssd data files.
#     (optional) - Defaults to "" (use database_dir). UI parameter.
#
# [*database_minimum_diskGB*]
#     Minimum disk space needed in GB for database.
#     (optional) - Defaults to 256
#
# [*keystone_ip*]
#     Control interface IP address of server where keystone service is
#     running. Used only in non-HA configuration, where keystone service
#     is running on a server other than other openstack services.
#     (optional) - Defaults to "" (use openstack_ip). UI parameter.
#
# [*keystone_admin_password*]
#     Admin password for keystone service.
#     (optional) - Defaults to "contrail123". UI parameter.
#
# [*keystone_admin_user*]
#     User Name for admin user of keystone service.
#     (optional) - Defaults to "admin". UI parameter.
#
# [*keystone_admin_tenant*]
#     Name for admin tenant or project of keystone service.
#     (optional) - Defaults to "admin". UI parameter.
#
# [*keystone_service_tenant*]
#     Name for service tenant or project of keystone service.
#     (optional) - Defaults to "services". UI parameter.
#
# [*keystone_region_name*]
#     Name for region in keystone..
#     (optional) - Defaults to "RegionOne". UI parameter.
#
# [*multi_tenancy*]
#     Flag to indicate if multi tenancy is enabled for openstack.
#     (optional) - Defaults to true.
#
# [*zookeeper_ip_list*]
#     List of control interface IP addresses of all the servers in cluster
#     running zookeeper services. UI parameter.
#     (optional) - Defaults to undef (use config_ip_list).
#
# [*quantum_port*]
#     IP port used by quantum/neutron.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "9697".
#
# [*quantum_service_protocol*]
#     IP protocol used by quantum.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "http".
#
# [*keystone_auth_protocol*]
#     Authentication protocol used by keystone.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "http".
#
# [*neutron_service_protocol*]
#     IP protocol used by neutron.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "http".
#
# [*keystone_auth_port*]
#     IP port used by keystone.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "35357".
#
# [*keystone_insecure_flag*]
#     Keystone insecure flag
#     Not exposed to SM for modification.
#     (optional) - Defaults to false.
#
# [*api_nworkers*]
#     Number of worker threads for API service.
#     Not exposed to SM for modification.
#     (optional) - Defaults to 1.
#
# [*haproxy_flag*]
#     Flag to indicate if haproxy is to be used. If
#     contrail_internal_vip/internal_vip is being used, even
#     if haproxy flag is set, value of false is passed to modules.
#     (optional) - Defaults to false. UI parameter.
#
# [*manage_neutron*]
#     if manage_neutron is false, neutron service tenant/user/role
#     is not created in keystone by contrail.
#     Not exposed to SM for modification.
#     (optional) - Defaults to true.
#
# [*openstack_manage_amqp*]
#     flag to indicate if amqp server is on openstack or contrail
#     config node.
#     Not exposed to SM for modification.
#     (optional) - Defaults to true (managed by contrail config).
#
# [*amqp_server_ip*]
#     If amqp is managed by openstack, if it is running on a separate
#     server, specify control interface IP of that server.
#     (optional) - Defaults to "" (same as openstack_ip).
#
# [*zk_ip_port*]
#     IP port used by zookeeper service.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "2181".
#
# [*hc_interval*]
#     Discovery service health check interval in seconds.
#     (optional) - Defaults to 5. UI parameter.
#
# [*vmware_ip*]
#     vmware ip address for cluster wth ESXi server.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "" (No ESXi or vmware configuration).
#
# [*vmware_username*]
#     vmware username for cluster with esxi server.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "" (No ESXi or vmware configuration).
#
# [*vmware_password*]
#     vmware password for cluster with ESXi server.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "" (No ESXi or vmware configuration).
#
# [*vmware_vswitch*]
#     vmware vswitch for cluster with ESXi server.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "" (No ESXi or vmware configuration).
#
# [*mysql_root_password*]
#     Root password for mysql access.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "c0ntrail123"
#
# [*openstack_mgmt_ip_list*]
#     List of management interface IP addresses of all the servers in cluster
#     configured to run contrail openstack node.
#     (optional) - Defaults to undef (same as openstack_ip_list)
#
# [*encap_priority*]
#     Encapsulation priority setting.
#     (optional) - Defaults to "VXLAN,MPLSoUDP,MPLSoGRE"
#
# [*router_asn*]
#     Router ASN value
#     (optional) - Defaults to "64512"
#
# [*metadata_secret*]
#     Metadata secret value.
#     Not exposed to SM for modification.
#     (optional) - Defaults to ""
#
# [*vgw_public_subnet*]
#     Virtual gateway public subnet value.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "".
#
# [*vgw_public_vn_name*]
#     Virtual gateway public VN name.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "".
#
# [*vgw_interface*]
#     Virtual gateway interface value.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "".
#
# [*vgw_gateway_routes*]
#     Virtual gateway routes
#     Not exposed to SM for modification.
#     (optional) - Defaults to "".
#
# [*orchestrator*]
#     Orchestrator value.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "openstack".
#
# [*contrail_repo_name*]
#     Contrail repository name from which to fetch packages.
#
# [*contrail_repo_type*]
#     Repo type for contrail repos to be created.
#
# [*contrail_repo_ip*]
#     IP address of server where contrail repo is created.
#     This would be same as server manager (puppet master) IP.
#     (optional) - Defaults to $serverip
#
# [*kernel_upgrade*]
#     Flag to indicate where to update kernel (true/false).
#     Not exposed to SM for modification.
#     (optional) - Defaults to true.
#
# [*kernel_version*]
#     kernel version to upgrade to.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "".
#
# [*storage_num_osd*]
#     Storage parameter needed only if storage role is configured.
#     (optional) - Defaults to "".
#
# [*storage_fsid*]
#     Storage parameter needed only if storage role is configured.
#     (optional) - Defaults to "".
#
# [*storage_num_hosts*]
#     Storage parameter needed only if storage role is configured.
#     (optional) - Defaults to "".
#
# [*storage_monitor_secret*]
#     Storage parameter needed only if storage role is configured.
#     (optional) - Defaults to "".
#
# [*osd_bootstrap_key*]
#     Storage parameter needed only if storage role is configured.
#     (optional) - Defaults to "".
#
# [*storage_admin_key*]
#     Storage parameter needed only if storage role is configured.
#     (optional) - Defaults to "".
#
# [*storage_virsh_uuid*]
#     Storage parameter needed only if storage role is configured.
#     (optional) - Defaults to "".
#
# [*storage_monitor_hosts*]
#     Storage parameter needed only if storage role is configured.
#     (optional) - Defaults to "".
#
# [*storage_osd_disks*]
#     Storage parameter needed only if storage role is configured.
#     (optional) - Defaults to "".
#
# [*storage_enabled*]
#     Storage parameter needed only if storage role is configured.
#     This parameter tells if storage is configured or not.
#     (optional) - Defaults to "".
#
# [*nfs_server*]
#     IP address of NFS server to store/get glance images. Used for
#     HA configuration only. UI parameter.
#     (optional) - Defaults to "" (no HA configuration).
#
# [*nfs_glance_path*]
#     Complete path of NFS mount to store glance images.
#     HA configuration only. UI parameter.
#     (optional) - Defaults to "" (no HA configuration).
#
# [*host_non_mgmt_ip*]
#     Specify address of data/control interface, only if there are separate interfaces
#     for management and data/control. If system has single interface for both, leave
#     default value of "".
#     (optional) - Defaults to "" (no multinetting - mgmt = data/ctrl).
#
# [*host_non_mgmt_gateway*]
#     Gateway IP address of the data interface of the server. If server has separate
#     interfaces for management and control/data, this parameter should provide gateway
#     ip address of data interface. UI parameter.
#     (optional) - Defaults to "" (no multinetting - mgmt = data/ctrl).
#
# [*openstack_passwd_list*]
#     List of passwords of all the nodes running openstack node
#     so that SSH can be done to those hosts to setup config.
#     Needed for HA configuration only.
#     (optional) - Defaults to "" (no HA configuration).
#
# [*openstack_user_list*]
#     List of user ids of all the nodes running openstack node
#     so that SSH can be done to those hosts to setup config.
#     Needed for HA configuration only.
#     (optional) - Defaults to "" (no HA configuration).
#
# [*compute_passwd_list*]
#     List of passwords of all the nodes running compute node
#     so that SSH can be done to those hosts to setup config.
#     Needed for HA configuration only.
#     (optional) - Defaults to "" (no HA configuration).
#
# [*host_roles*]
#     List of contrail roles configured on this server. Used
#     mostly by storage module to check if storage is one of
#     the roles configured on this server.
#     (optional) - Defaults to "" (no storage configuration).
#
# [*external_bgp*]
#     IP address of external BGP router.
#     (optional) - Defaults to "" (no external BGP router).
#
# [*contrail_plugin_location*]
#     path to contrail neutron plugin. Use default value.
#     Not exposed to SM for modification.
#     (optional) - Defaults to "/etc/neutron/plugins/opencontrail/ContrailPlugin.ini".
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
# [*enable_provision_started*]
#     Flag to include or exclude reporting of provision_started during catalog execution to server manager.
#     (optional) - Defaults to true (when included in node definition, enable the module logic).
#
# [*enable_keepalived*]
#     Flag to include or exclude keepalived module functionality dynamically.
#     (optional) - Defaults to true (when included in node definition, enable the module logic).
#
# [*enable_haproxy*]
#     Flag to include or exclude haproxy module functionality dynamically.
#     (optional) - Defaults to true (when included in node definition, enable the module logic).
#
# [*enable_database*]
#     Flag to include or exclude database module functionality dynamically.
#     (optional) - Defaults to true (when included in node definition, enable the module logic).
#
# [*enable_openstack*]
#     Flag to include or exclude openstack module functionality dynamically.
#     (optional) - Defaults to true (when included in node definition, enable the module logic).
#
# [*enable_control*]
#     Flag to include or exclude controller module functionality dynamically.
#     (optional) - Defaults to true (when included in node definition, enable the module logic).
#
# [*enable_config*]
#     Flag to include or exclude config module functionality dynamically.
#     (optional) - Defaults to true (when included in node definition, enable the module logic).
#
# [*enable_collector*]
#     Flag to include or exclude collector module functionality dynamically.
#     (optional) - Defaults to true (when included in node definition, enable the module logic).
#
# [*enable_webui*]
#     Flag to include or exclude webui module functionality dynamically.
#     (optional) - Defaults to true (when included in node definition, enable the module logic).
#
# [*enable_compute*]
#     Flag to include or exclude compute module functionality dynamically.
#     (optional) - Defaults to true (when included in node definition, enable the module logic).
#
# [*enable_pre_exec_vnc_galera*]
#     Flag to include or exclude pre exec vnc galera logic of openstack HA module (ha_config)
#     (optional) - Defaults to true (when included in node definition, enable the module logic).
#
# [*enable_post_exec_vnc_galera*]
#     Flag to include or exclude post exec vnc galera logic of openstack HA module (ha_config)
#     (optional) - Defaults to true (when included in node definition, enable the module logic).
#
# [*enable_post_provision*]
#     Flag to include or exclude reporting of status during catalog execution to server manager.
#     (optional) - Defaults to true (when included in node definition, enable the module logic).
#
# [*enable_sequence_provisioning*]
#     Flag to indicate if sequence provisioning logic is enabled. If true, explicit wait
#     within puppet manifest is not used and we rely on sequencing to help with that.
#     (optional) - Defaults to false.
#
# [*enable_ceilometer*]
#     Flag to include or exclude ceilometer service as part of openstack module dynamically.
#     (optional) - Defaults to false.
#
# [*xmpp_auth_enable*]
#     Flag for enabling xmpp autherization via cert exchange between agent and control.
#     (optional) - Defaults to false.
#
# [*xmpp_dns_auth_enable*]
#     Flag for enabling xmpp dns autherization via cert exchange between agent and control.
#     (optional) - Defaults to false.
#
# [*contrail_amqp_ip_list*]
#     User provided list of amqp server ips which have already been provisioned with rabbit instead of config nodes
#     (optional) - Defaults to ''.
#
# [*contrail_amqp_port*]
#     User provided port for amqp service
#     (optional) - Defaults to ''.
#
# [*openstack_amqp_ip_list*]
#     User provided list of amqp server ips for openstack services to use
#     (optional) - Defaults to ''.
#
# [*openstack_amqp_port*]
#     User provided port for amqp service
#     (optional) - Defaults to ''.
#
# [*nova_rabbit_hosts*]
#     AMQP IP list to use for Nova when using an external openstack/ for ISSU
#     (optional) - Defaults to undef
#
# [*nova_neutron_ip*]
#     Neutron IP to use for Nova when using an external openstack / for ISSU
#     (optional) - Defaults to undef
#
# [*keystone_mysql_service_password*]
#     The MySQL Password to use when connecting to a Central Keystone Server
#     (optional) - Defaults to undef
#
# [*external_openstack_ip*]
#     The IP Address of an External Openstack server the Contrail cluster connects to
#     (optional) - Defaults to undef
#
# [*config_manage_db*]
#     Flag to set for config node to have separate cassandra database cluster from collector
#     (optional) - Defaults to false
#
# [*global_controller_ip_list*]
#     List of interface IP addresses of all the servers in cluster
#     configured to be provisioned with global controller package.
#
# [*global_controller_name_list*]
#     List of host names of all the servers in cluster configured to
#     be provisioned with global controller package.
#
# [*global_controller_ip*]
#     ip address of the global controller that will control this region/cluster
#
# [*global_controller_port*]
#     global controller port
class contrail (
    $host_ip = undef,
    $uuid = undef,
    $config_ip_list = undef,
    $control_ip_list = undef,
    $database_ip_list = undef,
    $collector_ip_list = undef,
    $webui_ip_list = undef,
    $openstack_ip_list = undef,
    $compute_ip_list = undef,
    $config_name_list = undef,
    $compute_name_list = undef,
    $control_name_list = undef,
    $database_name_list = undef,
    $collector_name_list = undef,
    $openstack_name_list = undef,
    $tsn_ip_list = '',
    $tsn_name_list = '',
    $internal_vip = '',
    $external_vip = '',
    $contrail_internal_vip = '',
    $contrail_external_vip = '',
    $internal_virtual_router_id = 102,
    $external_virtual_router_id = 101,
    $contrail_internal_virtual_router_id = 103,
    $contrail_external_virtual_router_id = 104,
    $database_ip_port = 9160,
    $analytics_data_ttl = 48,
    $analytics_config_audit_ttl = 2160,
    $analytics_statistics_ttl = 168,
    $analytics_flow_ttl = 2,
    $snmp_scan_frequency = 600,
    $snmp_fast_scan_frequency = 60,
    $topology_scan_frequency = 60,
    $analytics_syslog_port = -1,
    $use_certs = False,
    $puppet_server = '',
    $database_initial_token = 0,
    $database_dir = '/var/lib/cassandra',
    $analytics_data_dir = '',
    $ssd_data_dir = '',
    $database_minimum_diskGB = 256,
    $keystone_ip = '',
    $keystone_admin_password = 'undef',
    $keystone_admin_user = 'admin',
    $keystone_admin_tenant = 'admin',
    $keystone_service_tenant = 'services',
    $keystone_region_name = 'RegionOne',
    $multi_tenancy = true,
    $zookeeper_ip_list = undef,
    $quantum_port = 9697,
    $quantum_service_protocol = 'http',
    $keystone_auth_protocol = 'http',
    $neutron_service_protocol = 'http',
    $keystone_auth_port = 35357,
    $keystone_insecure_flag = false,
    $api_nworkers = 1,
    $haproxy_flag = false,
    $manage_neutron = true,
    $openstack_manage_amqp = false,
    $amqp_server_ip = '',
    $zk_ip_port = 2181,
    $hc_interval = 5,
    $vmware_ip = '',
    $vmware_username = '',
    $vmware_password = '',
    $vmware_vswitch = '',
    $mysql_root_password = undef,
    $nova_rabbit_hosts = undef,
    $nova_neutron_ip = undef,
    $openstack_mgmt_ip_list = undef,
    $encap_priority = 'VXLAN,MPLSoUDP,MPLSoGRE',
    $router_asn = 64512,
    $metadata_secret = '',
    $vgw_public_subnet = '',
    $vgw_public_vn_name = '',
    $vgw_interface = '',
    $vgw_gateway_routes = '',
    $orchestrator = 'openstack',
    $contrail_repo_name = undef,
    $contrail_repo_type = undef,
    $contrail_repo_ip = $serverip,
    $kernel_upgrade = false,
    $kernel_version = '',
    $redis_password = '',
    $storage_num_osd = '',
    $storage_fsid = '',
    $storage_num_hosts = '',
    $storage_monitor_secret = '',
    $osd_bootstrap_key = '',
    $storage_admin_key = '',
    $storage_virsh_uuid = '',
    $storage_monitor_hosts = '',
    $storage_ip_list = '',
    $storage_osd_disks = '',
    $storage_enabled = '',
    $storage_chassis_config = '',
    $storage_hostnames = '',
    $live_migration_host = '',
    $live_migration_ip = '',
    $live_migration_storage_scope = 'local',
    $nfs_server = '',
    $nfs_glance_path = '',
    $host_non_mgmt_ip = '',
    $host_non_mgmt_gateway = '',
    $storage_cluster_network = '',
    $openstack_passwd_list = undef,
    $openstack_user_list = undef,
    $compute_passwd_list = undef,
    $host_roles = '',
    $external_bgp = '',
    $sync_db = '',
    $contrail_plugin_location  = '/etc/neutron/plugins/opencontrail/ContrailPlugin.ini',
    $contrail_logoutput = false,
    $contrail_upgrade = false,
    $enable_lbaas = false,
    $enable_provision_started = true,
    $enable_keepalived = true,
    $enable_haproxy = true,
    $enable_database = true,
    $enable_openstack = true,
    $enable_control = true,
    $enable_config = true,
    $enable_collector = true,
    $enable_webui = true,
    $enable_compute = true,
    $enable_tsn = true,
    $enable_toragent = true,
    $enable_pre_exec_vnc_galera = true,
    $enable_post_exec_vnc_galera = true,
    $enable_post_provision = true,
    $enable_sequence_provisioning = false,
    $enable_storage_compute = true,
    $enable_storage_master = true,
    $enable_ceilometer = false,
    $tor_ha_config = "",
    $nova_override_config     = {'config' => {} },
    $glance_override_config   = {'config' => {} },
    $cinder_override_config   = {'config' => {} },
    $keystone_override_config = {'config' => {} },
    $neutron_override_config  = {'config' => {} },
    $ceilometer_override_config = {'config' => {} },
    $ceph_override_config     = {'config' => {} },
    $heat_override_config     = {'config' => {} },
    $contrail_version = '',
    $xmpp_auth_enable = false,
    $xmpp_dns_auth_enable = false,
    $package_sku = "juno",
    $core_mask = '',
    $huge_pages = '',
    $contrail_amqp_ip_list = undef,
    $contrail_amqp_port = '',
    $openstack_amqp_ip_list = undef,
    $openstack_amqp_port = '',
    $openstack_verbose= 'false',
    $openstack_debug ='false',
    $openstack_mysql_allowed_hosts = '127.0.0.1',
    $sriov = {},
    $qos = {},
    $sriov_enable = false,
    $keystone_mysql_service_password = undef,
    $external_openstack_ip = undef,
    $webui_key_file_path = '/etc/contrail/webui_ssl/cs-key.pem',
    $webui_cert_file_path = '/etc/contrail/webui_ssl/cs-cert.pem',
    $enable_global_controller = false,
    $config_manage_db = true,
    $global_controller_ip_list = undef,
    $global_controller_name_list = undef,
    $global_controller_ip = undef,
    $global_controller_port = undef,
    $rabbit_ssl_support = false,
    $config_amqp_use_ssl = undef,
    $os_amqp_use_ssl = undef,
    $config_hostnames = {'hostnames' => {}}
) {
    class { '::contrail::params':
        # Common Parameters
	orchestrator =>				hiera(contrail::orchestrator, hiera(contrail::params::orchestrator, $orchestrator)),
	host_ip =>				hiera(contrail::host_ip, hiera(contrail::params::host_ip, $hostip)),
	zookeeper_ip_list =>			hiera(contrail::zookeeper_ip_list, hiera(contrail::params::zookeeper_ip_list, $zookeeper_ip_list)),
	contrail_repo_name =>			hiera(contrail::contrail_repo_name, hiera(contrail::params::contrail_repo_name, $contrail_repo_name)),
	contrail_repo_type =>			hiera(contrail::contrail_repo_type, hiera(contrail::params::contrail_repo_type, $contrail_repo_type)),
	contrail_repo_ip =>			hiera(contrail::contrail_repo_ip, hiera(contrail::params::contrail_repo_ip, $contrail_repo_ip)),
	kernel_upgrade =>			hiera(contrail::kernel_upgrade, hiera(contrail::params::kernel_upgrade, $kernel_upgrade)),
	kernel_version =>			hiera(contrail::kernel_version, hiera(contrail::params::kernel_version, $kernel_version)),
	host_non_mgmt_ip =>			hiera(contrail::host_non_mgmt_ip, hiera(contrail::params::host_non_mgmt_ip, $host_non_mgmt_ip)),
	host_non_mgmt_gateway =>		hiera(contrail::host_non_mgmt_gateway, hiera(contrail::params::host_non_mgmt_gateway, $host_non_mgmt_gateway)),
	host_roles =>				hiera(contrail::host_roles, hiera(contrail::params::host_roles, $host_roles)),
	contrail_logoutput =>			hiera(contrail::contrail_logoutput, hiera(contrail::params::contrail_logoutput, $contrail_logoutput)),
	contrail_upgrade =>			hiera(contrail::contrail_upgrade, hiera(contrail::params::contrail_upgrade, $contrail_upgrade)),
	contrail_version =>			hiera(contrail::contrail_version, hiera(contrail::params::contrail_version, $contrail_version)),
	enable_lbaas =>				hiera(contrail::enable_lbaas, hiera(contrail::params::enable_lbaas, $enable_lbaas)),
	xmpp_auth_enable =>			hiera(contrail::xmpp_auth_enable, hiera(contrail::params::xmpp_auth_enable, $xmpp_auth_enable)),
	xmpp_dns_auth_enable =>			hiera(contrail::xmpp_dns_auth_enable, hiera(contrail::params::xmpp_dns_auth_enable, $xmpp_dns_auth_enable)),
        package_sku =>        hiera(contrail::package_sku, $package_sku),
        # HA Parameters
	haproxy_flag =>				hiera(contrail::ha::haproxy_enable, hiera(contrail::params::haproxy_flag, $haproxy_flag)),
	contrail_internal_vip =>		hiera(contrail::ha::contrail_internal_vip, hiera(contrail::params::contrail_internal_vip, $contrail_internal_vip)),
	contrail_external_vip =>		hiera(contrail::ha::contrail_external_vip, hiera(contrail::params::contrail_external_vip, $contrail_external_vip)),
	contrail_internal_virtual_router_id =>	hiera(contrail::ha::contrail_internal_virtual_router_id, hiera(contrail::params::contrail_internal_virtual_router_id, $contrail_internal_virtual_router_id)),
	contrail_external_virtual_router_id =>	hiera(contrail::ha::contrail_external_virtual_router_id, hiera(contrail::params::contrail_external_virtual_router_id, $contrail_external_virtual_router_id)),
	tor_ha_config =>			hiera(contrail::ha::tor_ha_config, hiera(contrail::params::tor_ha_config, $tor_ha_config)),
        # database Parameters
	database_ip_list =>			hiera(contrail::database::database_ip_list, hiera(contrail::params::database_ip_list, $database_ip_list)),
	database_name_list =>			hiera(contrail::database::database_name_list, hiera(contrail::params::database_name_list, $database_name_list)),
	database_ip_port =>			hiera(contrail::database::ip_port, hiera(contrail::params::database_ip_port, $database_ip_port)),
	database_initial_token =>		hiera(contrail::database::initial_token, hiera(contrail::params::database_initial_token, $database_initial_token)),
	database_dir =>				hiera(contrail::database::directory, hiera(contrail::params::database_dir, $database_dir)),
	database_minimum_diskGB =>		hiera(contrail::database::minimum_diskGB, hiera(contrail::params::database_minimum_diskGB, $database_minimum_diskGB)),
        # Analytics Parameters
	collector_ip_list =>			hiera(contrail::analytics::analytics_ip_list, hiera(contrail::params::collector_ip_list, $collector_ip_list)),
	collector_name_list =>			hiera(contrail::analytics::analytics_name_list, hiera(contrail::params::collector_name_list, $collector_name_list)),
	snmp_scan_frequency =>			hiera(contrail::analytics::snmp_scan_frequency, hiera(contrail::params::snmp_scan_frequency, $snmp_scan_frequency)),
	analytics_data_ttl =>			hiera(contrail::analytics::data_ttl, hiera(contrail::params::analytics_data_ttl, $analytics_data_ttl)),
	analytics_config_audit_ttl =>		hiera(contrail::analytics::config_audit_ttl, hiera(contrail::params::analytics_config_audit_ttl, $analytics_config_audit_ttl)),
	analytics_statistics_ttl =>		hiera(contrail::analytics::statistics_ttl, hiera(contrail::params::analytics_statistics_ttl, $analytics_statistics_ttl)),
	analytics_flow_ttl =>			hiera(contrail::analytics::flow_ttl, hiera(contrail::params::analytics_flow_ttl, $analytics_flow_ttl)),
	snmp_fast_scan_frequency =>		hiera(contrail::analytics::snmp_fast_scan_frequency, hiera(contrail::params::snmp_fast_scan_frequency, $snmp_fast_scan_frequency)),
	topology_scan_frequency  =>		hiera(contrail::analytics::topology_scan_frequency, hiera(contrail::params::topology_scan_frequency, $topology_scan_frequency)),
	analytics_syslog_port =>		hiera(contrail::analytics::syslog_port, hiera(contrail::params::analytics_syslog_port, $analytics_syslog_port)),
	analytics_data_dir =>			hiera(contrail::analytics::data_directory, hiera(contrail::params::analytics_data_dir, $analytics_data_dir)),
	ssd_data_dir =>				hiera(contrail::analytics::ssd_data_directory, hiera(contrail::params::ssd_data_dir, $ssd_data_dir)),
	redis_password =>			hiera(contrail::analytics::redis_password, hiera(contrail::params::redis_password, $redis_password)),
        # Control Parameters
	control_ip_list =>			hiera(contrail::control::control_ip_list, hiera(contrail::params::control_ip_list, $control_ip_list)),
	control_name_list =>			hiera(contrail::control::control_name_list, hiera(contrail::params::control_name_list, $control_name_list)),
	puppet_server =>			hiera(contrail::control::puppet_server, hiera(contrail::params::puppet_server, $puppet_server)),
	encap_priority =>			hiera(contrail::control::encapsulation_priority, hiera(contrail::params::encap_priority, $encap_priority)),
	router_asn =>				hiera(contrail::control::router_asn, hiera(contrail::params::router_asn, $router_asn)),
	external_bgp =>				hiera(contrail::control::external_bgp, hiera(contrail::params::external_bgp, $external_bgp)),
        #Global Controller Parameters
        global_controller_ip_list =>            hiera(contrail::global_controller::global_controller_ip_list, $global_controller_ip_list),
        global_controller_name_list =>          hiera(contrail::global_controller::global_controller_name_list, $global_controller_name_list),
        global_controller_ip =>                 hiera(contrail::global_controller::global_controller_ip, hiera(contrail::params::global_controller_ip, $global_controller_ip)),
        global_controller_port =>               hiera(contrail::global_controller::global_controller_port, hiera(contrail::params::global_controller_port, $global_controller_port)),
        # Openstack Parameters
	openstack_controller_address_api =>     hiera(openstack::controller::address::api, hiera(contrail::params::openstack_controller_address_api, $openstack_controller_address_api)),
	openstack_controller_address_management => hiera(openstack::controller::address::management, hiera(contrail::params::openstack_controller_address_management, $openstack_controller_address_management)),
	openstack_ip_list =>			hiera(openstack::openstack_ip_list, hiera(contrail::params::openstack_ip_list, $openstack_ip_list)),
	openstack_name_list =>			hiera(openstack::openstack_name_list, hiera(contrail::params::openstack_name_list, $openstack_name_list)),
	openstack_passwd_list =>		hiera(openstack::openstack_passwd_list, hiera(contrail::params::openstack_passwd_list, $openstack_passwd_list)),
	openstack_user_list =>			hiera(openstack::openstack_user_list, hiera(contrail::params::openstack_user_list, $openstack_user_list)),
	openstack_mgmt_ip_list =>		hiera(openstack::openstack_mgmt_ip_list, hiera(contrail::params::openstack_mgmt_ip_list, $openstack_mgmt_ip_list)),
	enable_ceilometer =>			hiera(openstack::enable_ceilometer, hiera(contrail::params::enable_ceilometer, $enable_ceilometer)),
	multi_tenancy =>			hiera(openstack::multi_tenancy, hiera(contrail::params::multi_tenancy, $multi_tenancy)),
	metadata_secret =>			hiera(openstack::metadata_secret, hiera(contrail::params::metadata_secret, $metadata_secret)),
	openstack_manage_amqp =>		hiera(openstack::openstack_manage_amqp, hiera(contrail::params::openstack_manage_amqp, $openstack_manage_amqp)),
	keystone_region_name =>			hiera(openstack::region, hiera(contrail::params::keystone_region_name, $keystone_region_name)),
	keystone_ip =>				hiera(openstack::keystone::ip, hiera(contrail::params::keystone_ip, $keystone_ip)),
	external_openstack_ip =>		hiera(openstack::external_openstack_ip, hiera(contrail::params::external_openstack_ip, $external_openstack_ip)),
	keystone_mysql_service_password =>	hiera(openstack::keystone::mysql_service_password, hiera(contrail::params::keystone_mysql_service_password, $keystone_mysql_service_password)),
	keystone_admin_password =>		hiera(openstack::keystone::admin_password, hiera(contrail::params::keystone_admin_password, $keystone_admin_password)),
	keystone_admin_user =>			hiera(openstack::keystone::admin_user, hiera(contrail::params::keystone_admin_user, $keystone_admin_user)),
	keystone_admin_tenant =>		hiera(openstack::keystone::admin_tenant, hiera(contrail::params::keystone_admin_tenant, $keystone_admin_tenant)),
	keystone_service_tenant =>		hiera(openstack::keystone::service_tenant, hiera(contrail::params::keystone_service_tenant, $keystone_service_tenant)),
	keystone_auth_protocol =>		hiera(openstack::keystone::auth_protocol, hiera(contrail::params::keystone_auth_protocol, $keystone_auth_protocol)),
	keystone_auth_port =>			hiera(openstack::keystone::auth_port, hiera(contrail::params::keystone_auth_port, $keystone_auth_port)),
	keystone_insecure_flag =>		hiera(openstack::keystone::insecure_flag, hiera(contrail::params::keystone_insecure_flag, $keystone_insecure_flag)),
	quantum_port =>				hiera(openstack::neutron::port, hiera(contrail::params::quantum_port, $quantum_port)),
	quantum_service_protocol =>		hiera(openstack::neutron::service_protocol, hiera(contrail::params::quantum_service_protocol, $quantum_service_protocol)),
	neutron_service_protocol =>		hiera(openstack::neutron::service_protocol, hiera(contrail::params::neutron_service_protocol, $neutron_service_protocol)),
	mysql_root_password =>			hiera(openstack::mysql::root_password, hiera(contrail::params::mysql_root_password, $mysql_root_password)),
	nova_neutron_ip =>                      hiera(openstack::nova::neutron_ip, hiera(contrail::params::nova_neutron_ip, $nova_neutron_ip)),
	nova_rabbit_hosts =>                    hiera(openstack::nova::rabbit_hosts, hiera(contrail::params::nova_rabbit_hosts, $nova_rabbit_hosts)),
	amqp_server_ip =>			hiera(openstack::amqp::server_ip, hiera(contrail::params::amqp_server_ip, $amqp_server_ip)),
        openstack_amqp_ip_list =>               hiera(openstack::amqp::ip_list, hiera(contrail::params::openstack_amqp_ip_list, $openstack_amqp_ip_list)),
        openstack_amqp_port =>                  hiera(openstack::amqp::port, hiera(contrail::params::openstack_amqp_port, $openstack_amqp_port)),
        rabbit_ssl_support  =>     hiera(contrail::amqp_ssl, $rabbit_ssl_support),
        config_amqp_ssl     =>     hiera(contrail::config::amqp_use_ssl, $config_amqp_use_ssl),
        openstack_amqp_ssl  =>     hiera(openstack::amqp::use_ssl, $os_amqp_use_ssl),

    os_verbose                => hiera(openstack::verbose, $openstack_verbose),
    os_debug                  => hiera(openstack::debug, $openstack_debug),
    os_region                 => hiera(openstack::region, $openstack_region),
    os_mysql_allowed_hosts    => hiera(openstack::mysql::allowed_hosts, $openstack_mysql_allowed_hosts),
    os_rabbitmq_user          => hiera(openstack::rabbitmq::user,$openstack_rabbitmq_user),
    os_rabbitmq_password      => hiera(openstack::rabbitmq::password,$openstack_rabbitmq_password),
    os_nova_password          => hiera(openstack::nova::password,$openstack_nova_password),
    os_neutron_password       => hiera(openstack::neutron::password,$openstack_neutron_password),
    os_glance_password        => hiera(openstack::glance::password,$openstack_glance_password),
    os_cinder_password        => hiera(openstack::cinder::password,$openstack_cinder_password),
    os_heat_password          => hiera(openstack::heat::password,$openstack_heat_password),
    os_heat_encryption_key    => hiera(openstack::heat::encryption_key ,$openstack_heat_encryption_key),
    os_mysql_service_password => hiera(openstack::mysql::service_password,$openstack_mysql_service_password),
    ##TODO: current this value is a no-op.
    os_neutron_shared_secret  => hiera(openstack::neutron::shared_secret, $os_neutron_shared_secret),
    os_glance_mgmt_address    => hiera(openstack::storage::address::management, $os_glance_mgmt_address),
    os_glance_api_address     => hiera(openstack::storage::address::api, $os_glance_api_address),
    os_controller_mgmt_address=> hiera(openstack::controller::address::management, $os_controller_mgmt_address),
    os_controller_api_address => hiera(openstack::controller::address::api, $os_controller_api_address),
    os_keystone_admin_email   => hiera(openstack::keystone::admin_email, $keystone_admin_email),
    os_keystone_admin_token   => hiera(openstack::keystone::admin_token, $keystone_admin_token),
    os_mongo_password         => hiera(openstack::ceilometer::mongo, $os_mongo_password),
    os_metering_secret        => hiera(openstack::ceilometer::meteringsecret, $os_metering_secret),
    os_ceilometer_password    => hiera(openstack::ceilometer::password, $os_ceilometer_password),

    nova_private_key          => hiera(openstack::nova::ssh_private_key, $nova_private_key),
    nova_public_key           => hiera(openstack::nova::ssh_public_key, $nova_public_key),
        # Openstack HA Parameters
	internal_vip =>				hiera(openstack::ha::internal_vip, hiera(contrail::params::internal_vip, $internal_vip)),
	external_vip =>				hiera(openstack::ha::external_vip, hiera(contrail::params::external_vip, $external_vip)),
	internal_virtual_router_id =>		hiera(openstack::ha::internal_virtual_router_id, hiera(contrail::params::internal_virtual_router_id, $internal_virtual_router_id)),
	external_virtual_router_id =>		hiera(openstack::ha::external_virtual_router_id, hiera(contrail::params::external_virtual_router_id, $external_virtual_router_id)),
	nfs_server =>				hiera(openstack::ha::nfs_server, hiera(contrail::params::nfs_server, $nfs_server)),
	nfs_glance_path =>			hiera(openstack::ha::nfs_glance_path, hiera(contrail::params::nfs_glance_path, $nfs_glance_path)),
        # Config Parameters
	config_ip_list =>			hiera(contrail::config::config_ip_list, hiera(contrail::params::config_ip_list, $config_ip_list)),
	config_name_list =>			hiera(contrail::config::config_name_list, hiera(contrail::params::config_name_list, $config_name_list)),
	api_nworkers =>				hiera(contrail::config::api_nworkers, hiera(contrail::params::api_nworkers, $api_nworkers)),
	uuid =>					hiera(contrail::config::uuid, hiera(contrail::params::uuid, $uuid)),
	use_certs =>				hiera(contrail::config::use_certs, hiera(contrail::params::use_certs, $use_certs)),
	manage_neutron =>			hiera(contrail::config::manage_neutron, hiera(contrail::params::manage_neutron, $manage_neutron)),
	zk_ip_port =>				hiera(contrail::config::zookeeper_ip_port, hiera(contrail::params::zk_ip_port, $zk_ip_port)),
	hc_interval =>				hiera(contrail::config::healthcheck_interval, hiera(contrail::params::hc_interval, $hc_interval)),
	contrail_plugin_location =>		hiera(contrail::config::contrail_plugin_location, hiera(contrail::params::contrail_plugin_location, $contrail_plugin_location)),
        contrail_amqp_ip_list =>                hiera(contrail::config::contrail_amqp_ip_list, hiera(contrail::params::contrail_amqp_ip_list, $contrail_amqp_ip_list)),
        contrail_amqp_port =>                   hiera(contrail::config::contrail_amqp_port, hiera(contrail::params::contrail_amqp_port, $contrail_amqp_port)),
        config_manage_db =>                     hiera(contrail::config::manage_db, $config_manage_db),
        # webui Parameters
	webui_ip_list =>			hiera(contrail::webui::webui_ip_list, hiera(contrail::params::webui_ip_list, $webui_ip_list)),
        # compute Parameters
	compute_ip_list =>			hiera(contrail::compute::compute_ip_list, hiera(contrail::params::compute_ip_list, $compute_ip_list)),
	compute_name_list =>			hiera(contrail::compute::compute_name_list, hiera(contrail::params::compute_name_list, $compute_name_list)),
	compute_passwd_list =>			hiera(contrail::compute::compute_passwd_list, hiera(contrail::params::compute_passwd_list, $compute_passwd_list)),
        huge_pages =>                           hiera(contrail::compute::dpdk::huge_pages, hiera(contrail::params::huge_pages, $huge_pages)),
        core_mask => 	                        hiera(contrail::compute::dpdk::core_mask, hiera(contrail::params::core_mask, $core_mask)),
        sriov     =>                            hiera(contrail::compute::sriov,hiera(contrail::params::sriov, $sriov)),
        sriov_enable              => hiera(contrail::openstack::sriov::enable, hiera(contrail::params::sriov_enable, $sriov_enable)),

        # QoS Parameters
	qos =>					hiera(contrail::qos, $qos),
        # VMWare Parameters
	vmware_ip =>				hiera(contrail::vmware::ip, hiera(contrail::params::vmware_ip, $vmware_ip)),
	vmware_username =>			hiera(contrail::vmware::username, hiera(contrail::params::vmware_username, $vmware_username)),
	vmware_password =>			hiera(contrail::vmware::password, hiera(contrail::params::vmware_password, $vmware_password)),
	vmware_vswitch =>			hiera(contrail::vmware::vswitch, hiera(contrail::params::vmware_vswitch, $vmware_vswitch)),
        # Virtual Gateway Parameters
	vgw_public_subnet =>			hiera(contrail::vgw::public_subnet, hiera(contrail::params::vgw_public_subnet, $vgw_public_subnet)),
	vgw_public_vn_name =>			hiera(contrail::vgw::public_vn_name, hiera(contrail::params::vgw_public_vn_name, $vgw_public_vn_name)),
	vgw_interface =>			hiera(contrail::vgw::interface, hiera(contrail::params::vgw_interface, $vgw_interface)),
	vgw_gateway_routes =>			hiera(contrail::vgw::gateway_routes, hiera(contrail::params::vgw_gateway_routes, $vgw_gateway_routes)),
        # Storage Parameters
	storage_ip_list =>			hiera(contrail::storage::storage_ip_list, hiera(contrail::params::storage_ip_list, $storage_ip_list)),
	storage_hostnames => hiera(contrail::storage::storage_hostnames, hiera(contrail::params::storage_hostnames, $storage_hostnames)),
	storage_num_osd =>			hiera(contrail::storage::storage_num_osd, hiera(contrail::params::storage_num_osd, $storage_num_osd)),
	storage_fsid =>				hiera(contrail::storage::storage_fsid, hiera(contrail::params::storage_fsid, $storage_fsid)),
	storage_num_hosts =>			hiera(contrail::storage::storage_num_hosts, hiera(contrail::params::storage_num_hosts, $storage_num_hosts)),
        storage_monitor_secret =>               hiera(contrail::storage::storage_monitor_secret, hiera(contrail::params::storage_monitor_secret, $storage_monitor_secret)),
	osd_bootstrap_key =>			hiera(contrail::storage::osd_bootstrap_key, hiera(contrail::params::osd_bootstrap_key, $osd_bootstrap_key)),
	storage_admin_key =>                    hiera(contrail::storage::storage_admin_key, hiera(contrail::params::storage_admin_key, $storage_admin_key)),
	storage_virsh_uuid =>			hiera(contrail::storage::storage_virsh_uuid, hiera(contrail::params::storage_virsh_uuid, $storage_virsh_uuid)),
	storage_monitor_hosts =>		hiera(contrail::storage::storage_monitor_hosts, hiera(contrail::params::storage_monitor_hosts, $storage_monitor_hosts)),
	storage_osd_disks =>			hiera(contrail::storage::storage_osd_disks, hiera(contrail::params::storage_osd_disks, $storage_osd_disks)),
	storage_enabled =>			hiera(contrail::storage::storage_enabled, hiera(contrail::params::storage_enabled, $storage_enabled)),
	storage_chassis_config =>		hiera(contrail::storage::storage_chassis_config, hiera(contrail::params::storage_chassis_config, $storage_chassis_config)),
	live_migration_host =>			hiera(contrail::storage::live_migration_host, hiera(contrail::params::live_migration_host, $live_migration_host)),
	live_migration_ip =>			hiera(contrail::storage::live_migration_ip, hiera(contrail::params::live_migration_ip, $live_migration_ip)),
	live_migration_storage_scope =>		hiera(contrail::storage::live_migration_storage_scope, hiera(contrail::params::live_migration_storage_scope, $live_migration_storage_scope)),
	storage_cluster_network =>		hiera(contrail::storage::storage_cluster_network, hiera(contrail::params::storage_cluster_network, $storage_cluster_network)),
	storage_pool_config           => hiera(contrail::storage::pool_config, hiera(contrail::params::pool_config, $storage_pool_config)),
	storage_compute_name_list     => hiera(contrail::storage-compute::storage-compute_name_list, $storage_compute_name_list),
	storage_master_name_list      => hiera(contrail::storage-master::storage-master_name_list, $storage_master_name_list),
        #Webui Parameters
        webui_key_file_path =>                  hiera(contrail::webui::key_file_path, $webui_key_file_path),
        webui_cert_file_path =>                 hiera(contrail::webui::cert_file_path, $webui_cert_file_path),
        # tsn Parameters
	tsn_ip_list =>			        hiera(contrail::tsn::tsn_ip_list, hiera(contrail::params::tsn_ip_list, $tsn_ip_list)),
	tsn_name_list =>			hiera(contrail::tsn::tsn_name_list, hiera(contrail::params::tsn_name_list, $tsn_name_list)),
        # Sequencing Parameters (Never come as json input, generated by SM).
	enable_provision_started =>		hiera(contrail::sequencing::enable_provision_started, hiera(contrail::params::enable_provision_started, $enable_provision_started)),
	enable_keepalived =>			hiera(contrail::sequencing::enable_keepalived, hiera(contrail::params::enable_keepalived, $enable_keepalived)),
	enable_global_controller =>             hiera(contrail::sequencing::enable_global_controller, $enable_global_controller),
	enable_haproxy =>			hiera(contrail::sequencing::enable_haproxy, hiera(contrail::params::enable_haproxy, $enable_haproxy)),
	enable_database =>			hiera(contrail::sequencing::enable_database, hiera(contrail::params::enable_database, $enable_database)),
	enable_openstack =>			hiera(contrail::sequencing::enable_openstack, hiera(contrail::params::enable_openstack, $enable_openstack)),
	enable_control =>			hiera(contrail::sequencing::enable_control, hiera(contrail::params::enable_control, $enable_control)),
	enable_config =>			hiera(contrail::sequencing::enable_config, hiera(contrail::params::enable_config, $enable_config)),
	enable_collector =>			hiera(contrail::sequencing::enable_collector, hiera(contrail::params::enable_collector, $enable_collector)),
	enable_webui =>				hiera(contrail::sequencing::enable_webui, hiera(contrail::params::enable_webui, $enable_webui)),
	enable_compute =>			hiera(contrail::sequencing::enable_compute, hiera(contrail::params::enable_compute, $enable_compute)),
	enable_tsn =>				hiera(contrail::sequencing::enable_tsn, hiera(contrail::params::enable_tsn, $enable_tsn)),
	enable_toragent =>			hiera(contrail::sequencing::enable_toragent, hiera(contrail::params::enable_toragent, $enable_toragent)),
	enable_pre_exec_vnc_galera =>		hiera(contrail::sequencing::enable_pre_exec_vnc_galera, hiera(contrail::params::enable_pre_exec_vnc_galera, $enable_pre_exec_vnc_galera)),
	enable_post_exec_vnc_galera =>		hiera(contrail::sequencing::enable_post_exec_vnc_galera, hiera(contrail::params::enable_post_exec_vnc_galera, $enable_post_exec_vnc_galera)),
	enable_post_provision =>		hiera(contrail::sequencing::enable_post_provision, hiera(contrail::params::enable_post_provision, $enable_post_provision)),
	enable_sequence_provisioning  =>	hiera(contrail::sequencing::enable_sequence_provisioning, hiera(contrail::params::enable_sequence_provisioning, $enable_sequence_provisioning)),
	enable_storage_compute =>		hiera(contrail::sequencing::enable_storage_compute, hiera(contrail::params::enable_storage_compute, $enable_storage_compute)),
	enable_storage_master =>		hiera(contrail::sequencing::enable_storage_master, hiera(contrail::params::enable_storage_master, $enable_storage_master)),
        user_nova_config       => hiera(openstack::nova::override_config, $nova_override_config),
        user_glance_config     => hiera(openstack::glance::override_config, $glance_override_config),
        user_cinder_config     => hiera(openstack::cinder::override_config, $cinder_override_config),
        user_keystone_config   => hiera(openstack::keystone::override_config, $keystone_override_config),
        user_neutron_config    => hiera(openstack::neutron::override_config, $neutron_override_config),
        user_heat_config       => hiera(openstack::heat::override_config, $heat_override_config),
        user_ceilometer_config => hiera(openstack::ceilometer::override_config, $ceilometer_override_config),
        user_ceph_config       => hiera(openstack::ceph::override_config, $ceph_override_config),
        hostnames              => hiera(contrail::system, $config_hostnames)
    }
}
