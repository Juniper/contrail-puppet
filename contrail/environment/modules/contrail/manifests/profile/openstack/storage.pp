## configure contrail-storage to openstack services
class contrail::profile::openstack::storage(
  $pool_config = $::contrail::params::storage_pool_data['data'],
  $pool_names  = $::contrail::params::storage_pool_names,
  $fsid        = $::contrail::params::storage_fsid,
  $mon_hosts   = $::contrail::params::storage_monitor_hosts,
  $admin_key   = $::contrail::params::storage_admin_key,
  $mon_names   = $::contrail::params::storage_master_name_list
) {
  notice($pool_config)
  package {'contrail-storage':}
  package {'ceph':}
  ceph::key{'client.admin':
    secret         => $admin_key,
    cap_mon        => 'allow *',
    cap_osd        => 'allow *',
  }

  ceph_config {
    'global/fsid':                      value => $fsid;
    'global/mon_host':                  value => join($mon_hosts, ",");
    'global/mon_initial_members':       value => join($mon_names, ",");
    'global/auth_supported':            value => "cephx";
    'global/osd_journal_size':          value => "1024";
    'global/filestore_xattr_use_omap':  value => true;
    'global/rbd_cache':                 value => true;
    'global/rbd_default_format':        value => "2";
    'global/osd_heartbeat_grace':       value => "180";
    'global/debug_lockdep':             value => "0/0";
    'global/debug_context':             value => "0/0";
    'global/debug_crush':               value => "0/0";
    'global/debug_buffer':              value => "0/0";
    'global/debug_timer':               value => "0/0";
    'global/debug_filer':               value => "0/0";
    'global/debug_objecter':            value => "0/0";
    'global/debug_rados':               value => "0/0";
    'global/debug_rbd':                 value => "0/0";
    'global/debug_journaler':           value => "0/0";
    'global/debug_objectcatcher':       value => "0/0";
    'global/debug_client':              value => "0/0";
    'global/debug_osd':                 value => "0/0";
    'global/debug_optracker':           value => "0/0";
    'global/debug_objclass':            value => "0/0";
    'global/debug_filestore':           value => "0/0";
    'global/debug_journal':             value => "0/0";
    'global/debug_ms':                  value => "0/0";
    'global/debug_monc':                value => "0/0";
    'global/debug_tp':                  value => "0/0";
    'global/debug_auth':                value => "0/0";
    'global/debug_finisher':            value => "0/0";
    'global/debug_heartbeatmap':        value => "0/0";
    'global/debug_perfcounter':         value => "0/0";
    'global/debug_asok':                value => "0/0";
    'global/debug_throttle':            value => "0/0";
    'global/debug_mon':                 value => "0/0";
    'global/debug_paxos':               value => "0/0";
    'global/debug_rgw':                 value => "0/0";
    'global/throttler_perf_counter':    value => false;
    'osd/osd_op_threads':               value => "4";
    'osd/osd_disk_threads':             value => "2";
    'osd/osd_heartbeat_grace':          value => "180";
    'osd/osd_mount_options_xfs':        value => "rw,noatime,inode64,logbufs=8,logbsize=256k";
    'osd/osd_enable_op_tracker':        value => false;
    'osd/filestore_merge_threshold':    value => "40";
    'osd/filestore_split_multiple':     value => "8";
    'mon/mon_cluster_log_to_syslog':    value => true;
    'mon/mon_cluster_log_file':         value => "/var/log/ceph/ceph.log";
    'mon/mon_compact_on_start':         value => true;
  }

  notice($pool_names)
  notice(type($pool_names))

  cinder_config {
    'DEFAULT/enabled_backends': value => join($pool_names, ",");
  }
  create_resources('contrail::lib::storage_os_config', $pool_config, {})
  #glance_api_config {
    #'DEFAULT/workers'                  : value => '120';
    #'DEFAULT/show_image_direct_url'    : value => 'True';
    #'glance_store/default_store'       : value => 'rbd';
    #'glance_store/rbd_store_ceph_conf' : value => '/etc/ceph/ceph.conf';
    #'glance_store/rbd_store_user'      : value => 'images';
    #'glance_store/rbd_store_pool'      : value => 'images';
    #'glance_store/rbd_store_chunk_size': value => '8';
    #'glance_store/stores'              : value => 'glance.store.rbd.Store,glance.store.filesystem.Store,glance.store.http.Store';
  #}
}
