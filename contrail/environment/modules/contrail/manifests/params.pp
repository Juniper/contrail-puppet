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
#     (optional) - Defaults to "disable". UI parameter.
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
#     Flag to indicate where to update kernel (yes/no).
#     Not exposed to SM for modification.
#     (optional) - Defaults to "yes".
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
#     (optional) - Defaults to "NEUTRON_PLUGIN_CONFIG=\'/etc/neutron/plugins/opencontrail/ContrailPlugin.ini\'".
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
# [*amqp_ip_list*]
#     User provided list of amqp server ips which have already been provisioned with rabbit
#     (optional) - Defaults to false.
#
# [*amqp_port*]
#     User provided port for amqp service 
#     (optional) - Defaults to false.
#
class contrail::params (
    $host_ip,
    $uuid,
    $config_ip_list,
    $control_ip_list,
    $database_ip_list,
    $collector_ip_list,
    $webui_ip_list,
    $openstack_ip_list,
    $compute_ip_list,
    $tsn_ip_list = '',
    $config_name_list,
    $compute_name_list,
    $control_name_list,
    $database_name_list,
    $collector_name_list,
    $openstack_name_list,
    $tsn_name_list = '',
    $internal_vip = '',
    $external_vip = '',
    $contrail_internal_vip = '',
    $contrail_external_vip = '',
    $internal_virtual_router_id = 102,
    $external_virtual_router_id = 101,
    $contrail_internal_virtual_router_id = 103,
    $contrail_external_virtual_router_id = 104,
    $database_ip_port = '9160',
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
    $keystone_admin_password = 'contrail123',
    $keystone_admin_user = 'admin',
    $keystone_admin_tenant = 'admin',
    $keystone_service_tenant = 'services',
    $keystone_region_name = 'RegionOne',
    $multi_tenancy = true,
    $zookeeper_ip_list = undef,
    $quantum_port = '9697',
    $quantum_service_protocol = 'http',
    $keystone_auth_protocol = 'http',
    $neutron_service_protocol = 'http',
    $keystone_auth_port = 35357,
    $keystone_insecure_flag = false,
    $api_nworkers = 1,
    $haproxy_flag = 'disable',
    $manage_neutron = true,
    $openstack_manage_amqp = false,
    $amqp_server_ip = '',
    $zk_ip_port = '2181',
    $hc_interval = 5,
    $vmware_ip = '',
    $vmware_username = '',
    $vmware_password = '',
    $vmware_vswitch = '',
    $mysql_root_password = 'c0ntrail123',
    $openstack_mgmt_ip_list = undef,
    $encap_priority = 'VXLAN,MPLSoUDP,MPLSoGRE',
    $router_asn = '64512',
    $metadata_secret = '',
    $vgw_public_subnet = '',
    $vgw_public_vn_name = '',
    $vgw_interface = '',
    $vgw_gateway_routes = '',
    $orchestrator = 'openstack',
    $contrail_repo_name,
    $contrail_repo_type,
    $contrail_repo_ip = $serverip,
    $kernel_upgrade = 'yes',
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
    $openstack_passwd_list,
    $openstack_user_list,
    $compute_passwd_list,
    $host_roles = '',
    $external_bgp = '',
    $sync_db = '',
    $contrail_plugin_location  = 'NEUTRON_PLUGIN_CONFIG=\'/etc/neutron/plugins/opencontrail/ContrailPlugin.ini\'',
    $contrail_logoutput = false,
    $contrail_upgrade = false,
    $enable_lbass = false,
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
    $contrail_version = '',
    $amqp_ip_list = false,
    $amqp_port = false,
) {
    if (($contrail_internal_vip != '') or
        ($internal_vip != '') or
        ($haproxy_flag != 'enable')) {
        $haproxy = false
    }
    else {
        $haproxy = true
    }

    if ($zookeeper_ip_list == undef) {
        $zk_ip_list_to_use = $config_ip_list
    }
    else {
        $zk_ip_list_to_use = $zookeeper_ip_list
    }

    if ($openstack_mgmt_ip_list == undef) {
        $openstack_mgmt_ip_list_to_use = $openstack_ip_list
    } else {
        $openstack_mgmt_ip_list_to_use = $openstack_mgmt_ip_list
    }

    # Set keystone IP to be used.
    if ($keystone_ip != '') {
        $keystone_ip_to_use = $keystone_ip
    } elsif ($internal_vip != '') {
        $keystone_ip_to_use = $internal_vip
    } else {
        $keystone_ip_to_use = $openstack_ip_list[0]
    }

    #vip_to_use
    if $contrail_internal_vip != '' {
        $vip_to_use = $contrail_internal_vip
        $config_ip_to_use = $contrail_internal_vip
        $collector_ip_to_use = $contrail_internal_vip
    } elsif $internal_vip != '' {
        $vip_to_use = $internal_vip
        $config_ip_to_use = $internal_vip
        $collector_ip_to_use = $internal_vip
    } else {
        $vip_to_use = ''
        $config_ip_to_use = $config_ip_list[0]
        $collector_ip_to_use = $collector_ip_list[0]
    }

    # Set openstack_ip to be used to internal_vip, if internal_vip is not "".
    if ($internal_vip != '') {
        $openstack_ip_to_use = $internal_vip
        $discovery_ip_to_use = $internal_vip
    } else {
        $openstack_ip_to_use = $openstack_ip_list[0]
        $discovery_ip_to_use = $config_ip_list[0]
    }

    #rabbit host has same logic as config_ip
    $contrail_rabbit_host = $config_ip_to_use
    # Rabbit servers is a list of rabbitip1:rabbit_port,rabbitip2:rabbit_port,…..,rabbitipN:rabbit_port
    # rabbitip1,rabbitip2…..,rabbitipN will be cfgm1ip, cfgm2ip,….cfgmNip
    # If user supplies amqp_ip_list, use that instead of config_ip_list
    # If user supplies amqp_port, use that instead of contrail_rabbit_port
    if ($amqp_ip_list) {
        $contrail_rabbit_ip_list = $amqp_ip_list
    } else {
        $contrail_rabbit_ip_list = $config_ip_list
    }
    if ($amqp_port) {
        $contrail_rabbit_port = $amqp_port
    } else {
        $contrail_rabbit_port = '5672'
    }
    
    $contrail_rabbit_servers = inline_template('<%= @contrail_rabbit_ip_list.map{ |rabbitip| "#{rabbit_ip}:#{contrail_rabbit_port}" }.join(",") %>')

    # Set amqp_server_ip
    if ($::contrail::params::amqp_sever_ip != '') {
        $amqp_server_ip_to_use = $amqp_sever_ip
    } elsif ($openstack_manage_amqp) {
        $amqp_server_ip_to_use = $openstack_ip_to_use
    } else {
        $amqp_server_ip_to_use = $config_ip_to_use
    }
}
