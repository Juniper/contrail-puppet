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
    $contrail_storage_osd_disks = $::contrail::params::storage_osd_disks,
    $contrail_storage_hostname = $::hostname,
) inherits ::contrail::params {

    #include contrail::lib::storage_common
    # Main resource declarations for the class
    #notify { "disk-names => $contrail_storage_osd_disks" :;}
    if 'compute' in $contrail_host_roles { 
        if  $contrail_interface_rename_done == 2 {
	contrail::lib::storage_common { 'storage-compute':
	    contrail_storage_fsid => $contrail_storage_fsid,
            contrail_openstack_ip => $contrail_openstack_ip,
            contrail_host_roles => $contrail_host_roles,
            contrail_storage_num_osd => $contrail_storage_num_osd,
	    contrail_num_storage_hosts => $contrail_num_storage_hosts,
	    contrail_storage_mon_secret => $contrail_storage_mon_secret,
	    contrail_storage_osd_bootstrap_key => $contrail_storage_osd_bootstrap_key,
	    contrail_storage_admin_key => $contrail_storage_admin_key,
	    contrail_storage_virsh_uuid => $contrail_storage_virsh_uuid,
	    contrail_storage_mon_hosts => $contrail_storage_mon_hosts,
	    contrail_storage_osd_disks => $contrail_storage_osd_disks,
	    contrail_storage_hostname => $contrail_storage_hostname
	}
    }
    } else {
	contrail::lib::storage_common { 'storage-master':
	    contrail_storage_fsid => $contrail_storage_fsid,
            contrail_openstack_ip => $contrail_openstack_ip,
            contrail_storage_num_osd => $contrail_storage_num_osd,
            contrail_host_roles => $contrail_host_roles,
	    contrail_num_storage_hosts => $contrail_num_storage_hosts,
	    contrail_storage_mon_secret => $contrail_storage_mon_secret,
	    contrail_storage_osd_bootstrap_key => $contrail_storage_osd_bootstrap_key,
	    contrail_storage_admin_key => $contrail_storage_admin_key,
	    contrail_storage_virsh_uuid => $contrail_storage_virsh_uuid,
	    contrail_storage_mon_hosts => $contrail_storage_mon_hosts,
	    contrail_storage_osd_disks => $contrail_storage_osd_disks,
	    contrail_storage_hostname => $contrail_storage_hostname
	}
    }
}
