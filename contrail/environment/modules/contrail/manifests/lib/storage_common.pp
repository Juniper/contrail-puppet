##TODO: Document the class
define contrail::lib::storage_common(
  $contrail_storage_fsid,
  $contrail_storage_num_osd,
  $contrail_host_roles,
  $contrail_num_storage_hosts,
  $contrail_storage_mon_secret,
  $contrail_storage_osd_bootstrap_key,
  $contrail_storage_admin_key,
  $contrail_openstack_ip,
  $contrail_storage_virsh_uuid,
  $contrail_storage_ip_list,
  $contrail_storage_mon_hosts,
  $contrail_storage_osd_disks,
  $contrail_storage_hostname,
  $contrail_live_migration_host,
  $contrail_live_migration_ip,
  $contrail_lm_storage_scope,
  $contrail_storage_hostnames,
  $contrail_storage_chassis_config,
  $contrail_storage_cluster_network,
  $contrail_host_ip,
  $contrail_logoutput = false,
  $storge_pool_config        = $contrail::params::storage_pool_config,
  $storage_compute_name_list = $contrail::params::storage_compute_name_list,
  $storage_master_name_list  = $contrail::params::storage_master_name_list,
  $internal_vip = $contrail::params::internal_vip,
  $package_sku       = $::contrail::params::package_sku,
) {

  contrail::lib::report_status { 'storage_started': state => 'storage_started' }
  ->
  package { 'contrail-storage' : ensure => latest, }
  ->
  file { 'contrail-storage-rest-api.conf':
    ensure => present,
    path   => '/etc/init/ceph-rest-api.conf',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => "puppet:///modules/${module_name}/config-storage-rest-api.conf",
  } ->
  exec { 'ceph-rest-api' :
    command  => 'service ceph-rest-api restart',
    provider => shell,
    require  => File['contrail-storage-rest-api.conf']
  } ->
  file { 'ceph-osd-setup-file':
    ensure => present,
    path   => '/etc/contrail/contrail_setup_utils/config-storage-add-osd.sh',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => "puppet:///modules/${module_name}/config-storage-add-osd.sh",
  } ->
  file { 'ceph-disk-clean-file':
    ensure => present,
    path   => '/etc/contrail/contrail_setup_utils/config-storage-disk-clean.sh',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => "puppet:///modules/${module_name}/config-storage-disk-clean.sh",
  } ->
  file { 'ceph-log-rotate':
    ensure  => present,
    path    => '/etc/logrotate.d/ceph',
    mode    => '0755',
    owner   => root,
    group   => root,
    source  => "puppet:///modules/${module_name}/config-storage-ceph-log-rotate",
    require => [Package['contrail-storage'], Package['ceph']]
  } ->
  cron { 'ceph-logrotate':
    command  => '/usr/sbin/logrotate /etc/logrotate.d/ceph >/dev/null 2>&1',
    user     => root,
    minute   => '30',
    hour     => 'absent',
    month    => 'absent',
    monthday => 'absent',
    weekday  => 'absent',
  }

  $ceph_mon_hosts = join($contrail_storage_mon_hosts,",")

  class { 'ceph' :
    fsid            => $contrail_storage_fsid,
    mon_host        => $ceph_mon_hosts,
    keyring         => '/etc/ceph/$cluster.$name.keyring',
    public_network  => $contrail_storage_cluster_network,
  }

  $contrail_ceph_params = {
    'global/heartbeat_timeout'=> { value => '120' },
    #'global/rbd_cache'        => { value => 'true' },
    'global/debug_lockdep'    => { value => '0/0' },
    'global/debug_context'    => { value => '0/0' },
    'global/debug_crush'      => { value => '0/0' },
    'global/debug_buffer'     => { value => '0/0' },
    'global/debug_timer'      => { value => '0/0' },
    'global/debug_filer'      => { value => '0/0' },
    'global/debug_objecter'   => { value => '0/0' },
    'global/debug_rados'      => { value => '0/0' },
    'global/idebug_rbd'       => { value => '0/0' },
    'global/debug_journaler'  => { value => '0/0' },
    'global/debug_client'     => { value => '0/0' },
    'global/debug_osd'        => { value => '0/0' },
    'global/debug_optracker'  => { value => '0/0' },
    'global/debug_objclass'   => { value => '0/0' },
    'global/debug_filestore'  => { value => '0/0' },
    'global/debug_journal'    => { value => '0/0' },
    'global/debug_ms'         => { value => '0/0' },
    'global/debug_monc'       => { value => '0/0' },
    'global/debug_tp'         => { value => '0/0' },
    'global/debug_auth'       => { value => '0/0' },
    'global/debug_finisher'   => { value => '0/0' },
    'global/debug_perfcounter'=> { value => '0/0' },
    'global/debug_asok'       => { value => '0/0' },
    'global/debug_throttle'   => { value => '0/0' },
    'global/debug_mon'        => { value => '0/0' },
    'global/debug_paxos'      => { value => '0/0' },
    'global/debug_rgw'        => { value => '0/0' },
    'global/debug_objectcatcher'=> { value => '0/0' },
    'global/debug_heartbeatmap' => { value => '0/0' },
    'global/throttler_perf_counter'=> { value => 'false' },
    #'global/rbd_default_format' => { value => '2' },
    'client/rbd_cache'        => { value => 'true' },
    #'osd/osd_op_threads'      => { value => '4' },
    #'osd/osd_disk_threads'    => { value => '2' },
    'osd/osd_enable_op_tracker'    => { value => 'false' },
    'osd/filestore_merge_threshold'=> { value => '40' },
    'osd/filestore_split_multiple' => { value => '8' },
  }

  create_resources(ceph_config, $contrail_ceph_params, {} )

  if ($contrail_host_ip in $contrail_storage_mon_hosts) {
    ceph::mon { $contrail_storage_hostname:
      key => $contrail_storage_mon_secret,
      package_sku => $package_sku
    }
    $inject_keys = true
  } else {
    ceph::mon { $contrail_storage_hostname:
      ensure => absent,
      key    => $contrail_storage_mon_secret,
      package_sku => $package_sku
    }
    $inject_keys = false
  }

  ceph::key{'client.admin':
    secret         => $contrail_storage_admin_key,
    cap_mon        => 'allow *',
    cap_osd        => 'allow *',
    inject_as_id   => 'mon.',
    inject_keyring => "/var/lib/ceph/mon/ceph-$hostname/keyring",
    inject         => $inject_keys,
  }
  ->
  ceph::key{'client.bootstrap-osd':
    secret         => $contrail_storage_osd_bootstrap_key,
    keyring_path   => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
    cap_mon        => 'allow profile bootstrap-osd',
    inject_as_id   => 'mon.',
    inject_keyring => "/var/lib/ceph/mon/ceph-$hostname/keyring",
    inject         => $inject_keys,
  }

    if 'storage-compute' in $contrail_host_roles {
      if $contrail_storage_osd_disks != '' {
        contrail::lib::storage_disk { $contrail_storage_osd_disks:}
        -> Contrail::Lib::Report_status['storage-compute_completed']

        $pool_data = prefix($contrail_storage_osd_disks, "$contrail_storage_hostname:")
        $contrail_pool_map = join($pool_data, "', '")
        $host_num_disk = size($contrail_storage_osd_disks)

        ceph::pool {'internal': size => 1 } ->
        file { 'compute_pool_config' :
          path    => '/opt/contrail/bin/compute_pool_config.py',
          content => template("${module_name}/compute-pool-config.erb"),
          require => Package['contrail-storage']
        }
        ->
        exec { 'setup_compute_pool_config' :
          command   => 'python /opt/contrail/bin/compute_pool_config.py',
          provider  => shell,
          logoutput => $contrail_logoutput
        }
        -> Contrail::Lib::Report_status['storage-compute_completed']
      }
    }

    if 'openstack' in $contrail_host_roles {
        Ceph::Key<| title == 'client.bootstrap-osd' |> -> Exec['setup-config-storage-openstack']
        notify {"internal_vip => ${internal_vip}":;} ->
        cinder_config {
          'DEFAULT/enabled_backends'  : value => 'rbd-disk';
          'DEFAULT/rabbit_host'       : value => 'rbd-disk';
          'DEFAULT/rpc_backend'       : value => 'rabbit';
          'DEFAULT/enable_v1_api'     : value => 'false';
          'DEFAULT/enable_v2_api'     : value => 'true';
          'DEFAULT/auth_strategy'     : value => 'keystone';
          'DEFAULT/glance_api_version'     : value => '2';
          'keystone_authtoken/auth_uri'    : value => "http://${contrail_openstack_ip}:5000/v2.0";
          'keystone_authtoken/identity_uri': value => "http://${contrail_openstack_ip}:35357";
          'rbd-disk/volume_backend_name'   : value => 'RBD';
          'rbd-disk/rbd_pool'         : value => 'volumes';
          'rbd-disk/rbd_user'         : value => 'volumes';
          'rbd-disk/rbd_secret_uuid'  : value => $contrail_storage_virsh_uuid;
          'rbd-disk/volume_driver'    : value => 'cinder.volume.drivers.rbd.RBDDriver';
        } ->
        glance_api_config{
          'DEFAULT/workers'                  : value => '120';
          'DEFAULT/show_image_direct_url'    : value => 'True';
          'glance_store/default_store'       : value => 'rbd';
          'glance_store/rbd_store_ceph_conf' : value => '/etc/ceph/ceph.conf';
          'glance_store/rbd_store_user'      : value => 'images';
          'glance_store/rbd_store_pool'      : value => 'images';
          'glance_store/rbd_store_chunk_size': value => '8';
          'glance_store/stores'              : value => 'glance.store.rbd.Store,glance.store.filesystem.Store,glance.store.http.Store';
        } ->
        file { 'config-storage-openstack.sh':
            ensure => present,
            path   => '/etc/contrail/contrail_setup_utils/config-storage-openstack.sh',
            mode   => '0755',
            owner  => root,
            group  => root,
            source => "puppet:///modules/${module_name}/config-storage-openstack.sh"
        }
        ->
        exec { 'setup-config-storage-openstack' :
            command   => "/etc/contrail/contrail_setup_utils/config-storage-openstack.sh \
                             ${contrail_storage_virsh_uuid} ${contrail_openstack_ip} \
                             ${contrail_storage_num_osd} ${internal_vip} \
                             && echo setup-config-storage-openstack \
                             >> /etc/contrail/contrail-storage-exec.out" ,
            require   => File['config-storage-openstack.sh'],
            unless    => 'grep -qx setup-config-storage-openstack /etc/contrail/contrail-storage-exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
        }
        Exec['setup-config-storage-openstack']-> Contrail::Lib::Report_status['storage-master_completed']

        ## This should be defined only on one node.
        if size($storge_pool_config)  > 0 {
          $contrail_pool_map = join($storge_pool_config, "', '")
          $storage_compute_names = join($storage_compute_name_list,"', '")
          $storage_master_names  = join($storage_master_name_list,"', '")

          file { 'storage_pool_config' :
            path    => '/opt/contrail/bin/storage_pool_config.py',
            content => template("${module_name}/storage-pool-config.erb"),
            require => Package['contrail-storage']
          }
          ->
          exec { 'setup_storage_pool_config' :
            command   => 'python /opt/contrail/bin/storage_pool_config.py',
            provider  => shell,
            logoutput => $contrail_logoutput
          } ->
          file { 'storage_pool_openstack' :
            path    => '/opt/contrail/bin/storage_pool_openstack.py',
            content => template("${module_name}/storage_pool_openstack.erb"),
            require => Package['contrail-storage']
          }
          ->
          exec { 'setup_storage_openstack_config' :
            command   => 'python /opt/contrail/bin/storage_pool_openstack.py',
            provider  => shell,
            logoutput => $contrail_logoutput
          }
          -> Contrail::Lib::Report_status['storage-master_completed']
        }
        if size($contrail_storage_chassis_config)  > 0  {
            ## following is the format expected
            ##'["cmbu-is1-12:0","cmbu-ixs1-5:1","cmbu-gravity-11:0","cmbu-cl73:0"]'
            $contrail_chassis_map = inline_template('<%= @contrail_storage_chassis_config.map{ |hostname| "\'#{hostname}\'" }.join(", ")  %>')
            file { 'storage_chassis_config' :
                path    => '/opt/contrail/bin/contrail_storage_chassis_config.py',
                content => template("${module_name}/contrail-storage-chassis-config.erb"),
                require => Package['contrail-storage']
            }
              ->
              exec { 'setup_storage_chassis_config' :
                  command   => 'python /opt/contrail/bin/contrail_storage_chassis_config.py',
                  provider  => shell,
                  logoutput => $contrail_logoutput
              }
              Exec['setup_storage_chassis_config']-> Contrail::Lib::Report_status['storage-master_completed']
              if $contrail_live_migration_host != '' {
                  Exec['setup_storage_chassis_config']-> Exec['setup-config-storage-live-migration']
              }
              Exec['setup_storage_chassis_config']-> Ceph::Pool['data']
              Exec['setup_storage_chassis_config']-> Exec['setup-config-storage-openstack']
        }

        if $contrail_num_storage_hosts > 1 {
            $contrail_storage_replica_size = 2
        } else {
            $contrail_storage_replica_size = 1
        }

        $contrail_ceph_pg_num = 32 * $contrail_storage_num_osd
        ## if no disks on this host, don't run pools related stuf
        ceph::pool{['data', 'metadata', 'rbd']:
            ensure => absent
        }
        ->
        ceph::pool{'volumes':
            ensure  => present,
            size    => $contrail_storage_replica_size,
            pg_num  => $contrail_ceph_pg_num,
            pgp_num => $contrail_ceph_pg_num,
        }
        ->
        ceph::pool{'images':
            ensure  => present,
            size    => $contrail_storage_replica_size,
            pg_num  => $contrail_ceph_pg_num,
            pgp_num => $contrail_ceph_pg_num,
        }
        Ceph::Pool['images'] -> Contrail::Lib::Report_status['storage-master_completed']
        Ceph::Pool['images'] -> Exec['setup-config-storage-openstack']

        if $contrail_live_migration_host != '' {
            file { 'config-storage-live-migration.sh':
                ensure => present,
                path   => '/etc/contrail/contrail_setup_utils/config-storage-live-migration.sh',
                mode   => '0755',
                owner  => root,
                group  => root,
                source => "puppet:///modules/${module_name}/config-storage-live-migration.sh"
            }
            ->
            exec { 'setup-config-storage-live-migration':
                  command   => "/etc/contrail/contrail_setup_utils/config-storage-live-migration.sh \
                                 ${serverip}  ${contrail_live_migration_host} \
                                 ${contrail_storage_num_osd} ${contrail_openstack_ip} \
                                 ${contrail_live_migration_ip}" ,
                  provider  => shell,
                  timeout   => 0,
                  logoutput => $contrail_logoutput
            }
            Exec['setup-config-storage-openstack'] -> Exec['setup-config-storage-live-migration']
            Exec['setup-config-storage-live-migration']-> Contrail::Lib::Report_status['storage-master_completed']
        }
    }

    if 'compute' in $contrail_host_roles {
        Ceph::Key<| title == 'client.bootstrap-osd' |> -> Exec['setup-config-storage-compute']
        file { 'config-storage-compute.sh':
            ensure => present,
            path   => '/etc/contrail/contrail_setup_utils/config-storage-compute.sh',
            mode   => '0755',
            owner  => root,
            group  => root,
            source => "puppet:///modules/${module_name}/config-storage-compute.sh"
        }
        ->
        exec { 'setup-config-storage-compute' :
            command   => "/etc/contrail/contrail_setup_utils/config-storage-compute.sh \
                    ${contrail_storage_virsh_uuid} ${contrail_openstack_ip} \
                    && echo setup-config-storage-compute \
                    >> /etc/contrail/contrail-storage-exec.out" ,
            require   => File['config-storage-compute.sh'],
            unless    => 'grep -qx setup-config-storage-compute /etc/contrail/contrail-storage-exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
        }

        Exec['setup-config-storage-compute']-> Contrail::Lib::Report_status['storage-compute_completed']

        if ($contrail_live_migration_host =~ /(?i:enable)/ ) {
          file { 'config-storage-lm-compute.sh':
              ensure => present,
              path   => '/etc/contrail/contrail_setup_utils/config-storage-lm-compute.sh',
              mode   => '0755',
              owner  => root,
              group  => root,
              source => "puppet:///modules/${module_name}/config-storage-lm-compute.sh"
          }
          ->
          file { 'openstack-get-config':
              ensure => present,
              path   => '/etc/contrail/contrail_setup_utils/openstack-get-config',
              mode   => '0755',
              owner  => root,
              group  => root,
              source => "puppet:///modules/${module_name}/openstack-get-config"
          }
          ->
          exec { 'setup-config-storage-compute-live-migration':
              command   => "/etc/contrail/contrail_setup_utils/config-storage-lm-compute.sh \
                            ${contrail_live_migration_host} \
                            ${contrail_lm_storage_scope} \
                            ${contrail_live_migration_ip}" ,
              provider  => shell,
              timeout   => 0,
              logoutput => $contrail_logoutput
          } ->
          Contrail::Lib::Report_status['storage-compute_completed']

          Exec['setup-config-storage-compute'] -> Exec['setup-config-storage-compute-live-migration']
        }
    }

    Ceph::Key<| title == 'client.bootstrap-osd' |> -> Exec['ceph-volumes-key']
    Ceph::Key<| title == 'client.bootstrap-osd' |> -> Exec['ceph-images-key']

    exec { 'ceph-volumes-key':
        command => "/usr/bin/ceph auth get-or-create client.volumes \
                    mon 'allow r' osd 'allow class-read object_prefix rbd_children, \
                    allow rwx pool=volumes, allow rx pool=images' \
                    -o /etc/ceph/ceph.client.volumes.keyring",
        creates => '/etc/ceph/ceph.client.volumes.keyring',
    }
    ->
    exec { 'ceph-images-key':
        command => "/usr/bin/ceph auth get-or-create client.images \
                    mon 'allow r' osd 'allow class-read object_prefix rbd_children, \
                    allow rwx pool=images' -o /etc/ceph/ceph.client.images.keyring",
        creates => '/etc/ceph/ceph.client.images.keyring',
    }
    ->
    exec { 'ceph-virsh-secret' :
        command => "/bin/echo '<secret ephemeral=\"no\" private=\"no\"><uuid>\
                   ${contrail_storage_virsh_uuid}</uuid><usage type=\"ceph\">\
                   <name>client.volumes secret</name></usage></secret>' > secret.xml\
                   && /usr/bin/virsh secret-define --file secret.xml && /bin/rm secret.xml",
        unless  => "/usr/bin/virsh secret-list | grep -q ${contrail_storage_virsh_uuid}",
        require => Exec['ceph-volumes-key']
    }
    ->
    exec { 'ceph-virsh-set-secret' :
        command => "/usr/bin/virsh secret-set-value ${contrail_storage_virsh_uuid} \
                     --base64 `/usr/bin/ceph auth get client.volumes  | \
                     grep \"key = \" | awk '{printf \$3}'`",
        unless  => "/usr/bin/virsh secret-get-value ${contrail_storage_virsh_uuid}",
        require => Exec['ceph-virsh-secret']
    }
    ->
    file { '/etc/ceph/virsh.conf':
        ensure  => present,
        content => "hello new secret : ${contrail_storage_virsh_uuid}",
    }
    ->
    ## Currently only Ubuntu is supported
    service { 'ceph-virsh' :
        ensure     => running,
        name       => 'libvirt-bin',
        provider   => 'init',
        hasrestart => true,
        hasstatus  => true,
        require    => Exec['ceph-virsh-secret'],
        subscribe  => File['/etc/ceph/virsh.conf'],
    }
    ->
    contrail::lib::report_status { 'storage-master_completed': state => 'storage-master_completed' }
    contrail::lib::report_status { 'storage-compute_completed': state => 'storage-compute_completed' }
}
