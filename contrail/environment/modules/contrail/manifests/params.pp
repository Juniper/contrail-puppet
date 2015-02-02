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
#     (optional) - Defaults to "" (No openstack HA configured).
#
# [*contrail_internal_vip*]
#     Virtual IP address to be used for contrail HA functionality on
#     control/data interface.
#     This parameter is to be specified only if contrail HA IP address is
#     different from openstack HA. UI parameter.
#     (optional) - Defaults to "" (Follow internal_vip setting for contrail
#                  HA functionality).
#
# [*database_ip_port*]
#     IP port number used by database service.
#     (optional) - Defaults to "9160".
#
# [*analytics_data_ttl*]
#     Time to live (TTL) for analytics data in number of hours.
#     (optional) - Defaults to "48". UI parameter.
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
# [*keystone_ip*]
#     Control interface IP address of server where keystone service is
#     running. Used only in non-HA configuration, where keystone service
#     is running on a server other than other openstack services.
#     (optional) - Defaults to "" (use openstack_ip). UI parameter.
#
# [*keystone_admin_password*]
#     Admin password for keystone service. Manifests also use keystone_admin_token
#     to refer to this and hence is set to same value in this class.
#     (optional) - Defaults to "contrail123". UI parameter.
#
# [*keystone_service_token*]
#     Service token to access keystone service (MD5 hash generated). If not specified
#     simple value of "keystoneservicetoken" used.
#     to refer to this and hence is set to same value in this class.
#     (optional) - Defaults to "contrailservicetoken".
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
#     (optional) - Defaults to "service". UI parameter.
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
#     (optional) - Defaults to "9697".
#
# [*quantum_service_protocol*]
#     IP protocol used by quantum.
#     (optional) - Defaults to "http".
#
# [*keystone_auth_protocol*]
#     Authentication protocol used by keystone.
#     (optional) - Defaults to "http".
#
# [*neutron_service_protocol*]
#     IP protocol used by neutron.
#     (optional) - Defaults to "http".
#
# [*keystone_auth_port*]
#     IP port used by keystone.
#     (optional) - Defaults to "35357".
#
# [*keystone_insecure_flag*]
#     Keystone insecure flag
#     (optional) - Defaults to false.
#
# [*api_nworkers*]
#     Number of worker threads for API service.
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
#     (optional) - Defaults to true.
#
# [*openstack_manage_amqp*]
#     flag to indicate if amqp server is on openstack or contrail
#     config node.
#     (optional) - Defaults to true (managed by contrail config).
#
# [*amqp_server_ip*]
#     If amqp is managed by openstack, if it is running on a separate
#     server, specify control interface IP of that server.
#     (optional) - Defaults to "" (same as openstack_ip).
#
# [*zk_ip_port*]
#     IP port used by zookeeper service.
#     (optional) - Defaults to "2181".
#
# [*hc_interval*]
#     Discovery service health check interval in seconds.
#     (optional) - Defaults to 5. UI parameter.
#
# [*vmware_ip*]
#     vmware ip address for cluster wth ESXi server.
#     (optional) - Defaults to "" (No ESXi or vmware configuration).
#
# [*vmware_username*]
#     vmware username for cluster with esxi server.
#     (optional) - Defaults to "" (No ESXi or vmware configuration).
#
# [*vmware_password*]
#     vmware password for cluster with ESXi server.
#     (optional) - Defaults to "" (No ESXi or vmware configuration).
#
# [*vmware_vswitch*]
#     vmware vswitch for cluster with ESXi server.
#     (optional) - Defaults to "" (No ESXi or vmware configuration).
#
# [*keepalived_vrid*]
#     Virtual router id value used by keepalived (VRRP)
#     (optional) - Defaults to 100.
#
# [*mysql_root_password*]
#     Root password for mysql access.
#     (optional) - Defaults to "c0ntrail123"
#
# [*openstack_mgmt_ip_list*]
#     List of management interface IP addresses of all the servers in cluster
#     configured to run contrail openstack node.
#     (optional) - Defaults to undef (same as openstack_ip_list)
#
# [*encap_priority*]
#     Encapsulation priority setting.
#     (optional) - Defaults to "MPLSoUDP,MPLSoGRE,VXLAN"
#
# [*router_asn*]
#     Router ASN value
#     (optional) - Defaults to "64512"
#
# [*metadata_secret*]
#     Metadata secret value.
#     (optional) - Defaults to ""
#
# [*vgw_public_subnet*]
#     Virtual gateway public subnet value.
#     (optional) - Defaults to "".
#
# [*vgw_public_vn_name*]
#     Virtual gateway public VN name.
#     (optional) - Defaults to "".
#
# [*vgw_interface*]
#     Virtual gateway interface value.
#     (optional) - Defaults to "".
#
# [*vgw_gateway_routes*]
#     Virtual gateway routes
#     (optional) - Defaults to "".
#
# [*orchestrator*]
#     Orchestrator value.
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
#     (optional) - Defaults to "yes".
#
# [*kernel_version*]
#     kernel version to upgrade to.
#     (optional) - Defaults to "3.13.0-34".
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
#
# [*contrail_plugin_location*]
#     path to contrail neutron plugin. Use default value.
#     (optional) - Defaults to "NEUTRON_PLUGIN_CONFIG=\'/etc/neutron/plugins/opencontrail/ContrailPlugin.ini\'".
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
    $config_name_list,
    $compute_name_list,
    $control_name_list,
    $collector_name_list,
    $openstack_name_list,
    $internal_vip = "",
    $external_vip = "",
    $contrail_internal_vip = "",
    $database_ip_port = "9160",
    $analytics_data_ttl = 48,
    $analytics_syslog_port = -1,
    $use_certs = False,
    $puppet_server = '',
    $database_initial_token = 0,
    $database_dir = "/var/lib/cassandra",
    $analytics_data_dir = "",
    $ssd_data_dir = "",
    $keystone_ip = "",
    $keystone_admin_password = "contrail123",
    $keystone_service_token = "c0ntrail123",
    $keystone_admin_user = "admin",
    $keystone_admin_tenant = "admin",
    $keystone_service_tenant = "service",
    $keystone_region_name = "RegionOne",
    $multi_tenancy = false,
    $zookeeper_ip_list = undef,
    $quantum_port = "9697",
    $quantum_service_protocol = "http",
    $keystone_auth_protocol = "http",
    $neutron_service_protocol = "http",
    $keystone_auth_port = 35357,
    $keystone_insecure_flag = false,
    $api_nworkers = 1,
    $haproxy_flag = false,
    $manage_neutron = true,
    $openstack_manage_amqp = false,
    $amqp_server_ip = "",
    $zk_ip_port = '2181',
    $hc_interval = 5,
    $vmware_ip = "",
    $vmware_username = "",
    $vmware_password = "",
    $vmware_vswitch = "",
    $keepalived_vrid = 100,
    $mysql_root_password = "c0ntrail123",
    $openstack_mgmt_ip_list = undef,
    $encap_priority = "MPLSoUDP,MPLSoGRE,VXLAN",
    $router_asn = "64512",
    $metadata_secret = "",
    $vgw_public_subnet = "",
    $vgw_public_vn_name = "",
    $vgw_interface = "",
    $vgw_gateway_routes = "",
    $orchestrator = "openstack",
    $contrail_repo_name,
    $contrail_repo_type,
    $contrail_repo_ip = $serverip,
    $kernel_upgrade = "yes",
    $kernel_version = "3.13.0-34",
    $storage_num_osd = "",
    $storage_fsid = "",
    $storage_num_hosts = "",
    $storage_monitor_secret = "",
    $osd_bootstrap_key = "",
    $storage_admin_key = "",
    $storage_virsh_uuid = "",
    $storage_monitor_hosts = "",
    $storage_osd_disks = "",
    $storage_enabled = "",
    $nfs_server = "",
    $host_non_mgmt_ip = "",
    $host_non_mgmt_gateway = "",
    $openstack_passwd_list,
    $openstack_user_list,
    $compute_passwd_list,
    $host_roles,
    $kernel_upgrade = "yes",
    $kernel_version = "3.13.0-34",
    $external_bgp = "",
    $contrail_plugin_location  = "NEUTRON_PLUGIN_CONFIG=\'/etc/neutron/plugins/opencontrail/ContrailPlugin.ini\'"
) {
    # Manifests use keystone_admin_token to refer to keystone_admin_password too. Hence set
    # that varible here.
    $keystone_admin_token = $keystone_admin_password

    if (($contrail_internal_vip != "") or
        ($internal_vip != "")) {
        $haproxy = false
    }
    else {
        $haproxy = $haproxy_flag
    }

    if ($zookeeper_ip_list == undef) {
        $zk_ip_list_to_use = $config_ip_list
    }
    else {
        $zk_ip_list_to_use = $zookeeper_ip_list
    }

    if ($openstack_mgmt_ip_list == undef) {
        $openstack_mgmt_ip_list_to_use = $openstack_ip_list
    }
    else {
        $openstack_mgmt_ip_list_to_use = $openstack_mgmt_ip_list
    }
}
