class contrail::storage (
    $contrail_host_roles = $::contrail::params::host_roles,
    $contrail_openstack_ip = $::contrail::params::openstack_ip_list[0],
    $contrail_storage_num_osd = $::contrail::params::storage_num_osd,
    $contrail_storage_fsid = $::contrail::params::storage_fsid,
    $contrail_num_storage_hosts = $::contrail::params::storage_num_hosts,
    $contrail_storage_mon_secret = $::contrail::params::storage_monitor_secret,
    $contrail_storage_osd_bootstrap_key = $::contrail::params::osd_bootstrap_key,
    $contrail_storage_admin_key = $::contrail::params::storage_admin_key,
    $contrail_storage_virsh_uuid = $::contrail::params::storage_virsh_uuid,
    $contrail_storage_mon_hosts = $::contrail::params::storage_monitor_hosts,
    $contrail_storage_ip_list = $::contrail::params::storage_ip_list,
    $contrail_storage_osd_disks = $::contrail::params::storage_osd_disks,
    $contrail_storage_hostname = $::hostname,
    $contrail_live_migration_host = $::contrail::params::live_migration_host,
    $contrail_live_migration_ip = $::contrail::params::live_migration_ip,
    $contrail_lm_storage_scope = $::contrail::params::live_migration_storage_scope,
    $contrail_storage_cluster_network = $::contrail::params::storage_cluster_network,
    $contrail_storage_hostnames = $::contrail::params::storage_hostnames,
    $contrail_storage_chassis_config = $::contrail::params::storage_chassis_config,
    $contrail_host_ip = $::contrail::params::host_ip,
    $contrail_logoutput = $::contrail::params::contrail_logoutput
) inherits ::contrail::params {

    if ($::contrail::params::internal_vip != "") {
        $contrail_openstack_ip_use = $::contrail::params::internal_vip
    } else {
        $contrail_openstack_ip_use = $::contrail::params::openstack_ip_list[0]
    }
    #include contrail::lib::storage_common
    # Main resource declarations for the class
    #notify { "disk-names => $contrail_storage_osd_disks" :;}
    if 'compute' in $contrail_host_roles { 
    exec { "do-reboot-server-storage" :
        command => "/sbin/reboot && echo do-reboot-server >> /etc/contrail/contrail_common_exec.out",
        onlyif  => "grep -qx flag-reboot-server /etc/contrail/contrail_compute_exec.out",
        unless => "grep -qx do-reboot-server /etc/contrail/contrail_common_exec.out",
        provider => shell,
        logoutput => 'true'
    } -> 
        file {"update_interface_renamed":
            path=> "/etc/contrail/interface_renamed",
            ensure  => present,
            mode => 0644,
            content => "2"
        } 
        if  ($contrail_interface_rename_done == 2) {
        contrail::lib::storage_common { 'storage-compute':
            contrail_storage_fsid => $contrail_storage_fsid,
            contrail_openstack_ip => $contrail_openstack_ip_use,
            contrail_host_roles => $contrail_host_roles,
            contrail_storage_num_osd => $contrail_storage_num_osd,
            contrail_num_storage_hosts => $contrail_num_storage_hosts,
            contrail_storage_mon_secret => $contrail_storage_mon_secret,
            contrail_storage_osd_bootstrap_key => $contrail_storage_osd_bootstrap_key,
            contrail_storage_admin_key => $contrail_storage_admin_key,
            contrail_storage_virsh_uuid => $contrail_storage_virsh_uuid,
            contrail_storage_mon_hosts => $contrail_storage_mon_hosts,
            contrail_storage_ip_list => $contrail_storage_ip_list,
            contrail_storage_osd_disks => $contrail_storage_osd_disks,
            contrail_storage_hostname => $contrail_storage_hostname,
            contrail_live_migration_host => $contrail_live_migration_host,
            contrail_live_migration_ip => $contrail_live_migration_ip,
            contrail_lm_storage_scope => $contrail_lm_storage_scope,
            contrail_storage_hostnames => $contrail_storage_hostnames,
            contrail_storage_chassis_config => $contrail_storage_chassis_config,
            contrail_storage_cluster_network => $contrail_storage_cluster_network,
            contrail_host_ip => $contrail_host_ip,
            contrail_logoutput => $contrail_logoutput }
        } else {
            file { "contrail-storage-exit-file":
                path => "/etc/contrail/contrail_setup_utils/config-storage-exit.sh",
                ensure  => present,
                mode => 0755,
                owner => root,
                group => root,
                content => "exit 1",
           }
           ->
          exec { "contrail-storage-exit" :
              command => "/etc/contrail/contrail_setup_utils/config-storage-exit.sh",
              provider => shell,
          }
       }
    } else {
        contrail::lib::storage_common { 'storage-master':
            contrail_storage_fsid => $contrail_storage_fsid,
            contrail_openstack_ip => $contrail_openstack_ip_use,
            contrail_storage_num_osd => $contrail_storage_num_osd,
            contrail_host_roles => $contrail_host_roles,
            contrail_num_storage_hosts => $contrail_num_storage_hosts,
            contrail_storage_mon_secret => $contrail_storage_mon_secret,
            contrail_storage_osd_bootstrap_key => $contrail_storage_osd_bootstrap_key,
            contrail_storage_admin_key => $contrail_storage_admin_key,
            contrail_storage_virsh_uuid => $contrail_storage_virsh_uuid,
            contrail_storage_mon_hosts => $contrail_storage_mon_hosts,
            contrail_storage_ip_list => $contrail_storage_ip_list,
            contrail_storage_osd_disks => $contrail_storage_osd_disks,
            contrail_storage_hostname => $contrail_storage_hostname,
            contrail_live_migration_host => $contrail_live_migration_host,
            contrail_live_migration_ip => $contrail_live_migration_ip,
            contrail_lm_storage_scope => $contrail_lm_storage_scope,
            contrail_storage_hostnames => $contrail_storage_hostnames,
            contrail_storage_chassis_config => $contrail_storage_chassis_config,
            contrail_storage_cluster_network => $contrail_storage_cluster_network,
            contrail_host_ip => $contrail_host_ip,
            contrail_logoutput => $contrail_logoutput
        }
    }
}

