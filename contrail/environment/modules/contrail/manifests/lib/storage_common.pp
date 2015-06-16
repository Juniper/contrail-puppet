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
        $contrail_logoutput = false
        ) {

    contrail::lib::report_status { "storage_started": state => "storage_started" }
    ->
    package { 'contrail-storage-packages' : ensure => present, }
    ->
    package { 'contrail-storage' : ensure => present, }
    -> 
    file { 'contrail-storage-rest-api.conf':
        path => '/etc/init/ceph-rest-api.conf',
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
        source => "puppet:///modules/$module_name/config-storage-rest-api.conf",
    }
    ->
    exec { "ceph-rest-api" :
        command => "service ceph-rest-api restart",
        provider => shell,
        require => File['contrail-storage-rest-api.conf']
    } ->
    file { "ceph-osd-setup-file":
        path => "/etc/contrail/contrail_setup_utils/config-storage-add-osd.sh",
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
        source => "puppet:///modules/$module_name/config-storage-add-osd.sh",
    } ->

    file { "ceph-disk-clean-file":
        path => "/etc/contrail/contrail_setup_utils/config-storage-disk-clean.sh",
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
        source => "puppet:///modules/$module_name/config-storage-disk-clean.sh",
    } ->
        file { "ceph-log-rotate":
        path => "/etc/logrotate.d/ceph",
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
        source => "puppet:///modules/$module_name/config-storage-ceph-log-rotate",
        require => [Package['contrail-storage'], Package['ceph']]
        } ->
    cron { 'ceph-logrotate':
        command => '/usr/sbin/logrotate /etc/logrotate.d/ceph >/dev/null 2>&1',
        user    => root,
        minute  => '30',
        hour => 'absent',
        month => 'absent',
        monthday => 'absent',
        weekday => 'absent',
    }
    if size($contrail_storage_ip_list) > 10 {
        $contrail_storage_max_monitors = 10
    } else {
        $contrail_storage_max_monitors = size($contrail_storage_ip_list)
    }

    $contrail_ceph_monitors = inline_template('<%= @contrail_storage_ip_list.first(@contrail_storage_max_monitors) %>')
    notify {" monitors = $contrail_ceph_monitors":; }
    $contrail_ceph_monitors_map = inline_template('<%= @contrail_storage_ip_list.first(@contrail_storage_max_monitors).map{ |ip| "#{ip}" }.join(", ")  %>')

    file { "ceph-disk-clean-file1":
        path => "/etc/ceph/test2.conf",
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
        content => "hello new secret : $contrail_ceph_monitors ====> $contrail_ceph_monitors_map",
}
    class { 'ceph' : 
        fsid => $contrail_storage_fsid,
        mon_host => "$contrail_ceph_monitors_map",
        keyring => '/etc/ceph/$cluster.$name.keyring',
        cluster_network => $contrail_storage_cluster_network,
        #require => Package['contrail-storage'],
    }
    if ($contrail_host_ip in $contrail_ceph_monitors) {
        ceph::mon { $contrail_storage_hostname:
            key => $contrail_storage_mon_secret
        }
        ->
        ceph::key{'client.admin':
            secret => $contrail_storage_admin_key,
            cap_mon => 'allow *',
            cap_osd => 'allow *',
            inject_as_id => 'mon.',
            inject_keyring => "/var/lib/ceph/mon/ceph-$hostname/keyring",
            inject => true,
         }
         ->
         ceph::key{'client.bootstrap-osd':
            secret => $contrail_storage_osd_bootstrap_key,
            keyring_path => "/var/lib/ceph/bootstrap-osd/ceph.keyring",
            cap_mon => 'allow profile bootstrap-osd',
            inject_as_id => 'mon.',
            inject_keyring => "/var/lib/ceph/mon/ceph-$hostname/keyring",
            inject => true,
          }
    } else {
        ceph::key{'client.admin':
            secret => $contrail_storage_admin_key,
            cap_mon => 'allow *',
            cap_osd => 'allow *',
            #inject_as_id => 'mon.',
            #inject_keyring => "/var/lib/ceph/mon/ceph-$hostname/keyring",
            #inject => true,
         }
}

     if 'storage-compute' in $contrail_host_roles {
       if $contrail_storage_osd_disks != 'undef' {
          contrail::lib::prepare_disk{ $contrail_storage_osd_disks :
              contrail_logoutput => $contrail_logoutput
          } ->
          ceph::osd { $contrail_storage_osd_disks: 
              require => Contrail::Lib::Prepare_disk[$contrail_storage_osd_disks]
          } ->
          Contrail::Lib::Report_status['storage-compute_completed']
       }
     }

    if 'openstack' in $contrail_host_roles {
        Ceph::Key<| title == 'client.bootstrap-osd' |> -> Exec['setup-config-storage-openstack']
        file { "config-storage-openstack.sh":
            path => '/etc/contrail/contrail_setup_utils/config-storage-openstack.sh',
            ensure  => present,
            mode => 0755,
            owner => root,
            group => root,
            source => "puppet:///modules/$module_name/config-storage-openstack.sh"
        }
        -> 
        exec { "setup-config-storage-openstack" :
            command => "/etc/contrail/contrail_setup_utils/config-storage-openstack.sh \
                  ${contrail_storage_virsh_uuid} ${contrail_openstack_ip} $contrail_storage_num_osd \
                  && echo setup-config-storage-openstack \
                  >> /etc/contrail/contrail-storage-exec.out" ,
             require => File["config-storage-openstack.sh"],
             unless  => "grep -qx setup-config-storage-openstack /etc/contrail/contrail-storage-exec.out",
             provider => shell,
             logoutput => $contrail_logoutput
        }
        Exec['setup-config-storage-openstack']-> Contrail::Lib::Report_status['storage-master_completed']

        if $contrail_storage_chassis_config != '' {
             ##'["cmbu-is1-12:0","cmbu-ixs1-5:1","cmbu-gravity-11:0","cmbu-cl73:0"]'-
             $contrail_chassis_map = inline_template('<%= @contrail_storage_chassis_config.map{ |hostname| "\'#{hostname}\'" }.join(", ")  %>')
             file { "storage_chassis_config" :
                 path => '/opt/contrail/bin/contrail_storage_chassis_config.py',
                 content => template("$module_name/contrail-storage-chassis-config.erb"),
                 require => Package['contrail-storage']
              } 
              -> 
              exec { "setup_storage_chassis_config" :
                  command => 'python /opt/contrail/bin/contrail_storage_chassis_config.py',
                  provider => shell,
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
        ceph::pool{'data': ensure => absent}
        -> ceph::pool{'metadata': ensure => absent}
        -> ceph::pool{'rbd': ensure => absent}
        -> ceph::pool{'volumes': ensure => present,
                size => $contrail_storage_replica_size,
                pg_num => $contrail_ceph_pg_num,
                pgp_num => $contrail_ceph_pg_num,
        }
        -> ceph::pool{'images': ensure => present,
                size => $contrail_storage_replica_size,
                pg_num => $contrail_ceph_pg_num,
                pgp_num => $contrail_ceph_pg_num,
        }
        Ceph::Pool['images'] -> Contrail::Lib::Report_status['storage-master_completed']
        Ceph::Pool['images'] -> Exec['setup-config-storage-openstack']
    
        if $contrail_live_migration_host != '' {
            file { "config-storage-live-migration.sh":
                path => '/etc/contrail/contrail_setup_utils/config-storage-live-migration.sh',
                ensure  => present,
                mode => 0755,
                owner => root,
                group => root,
                source => "puppet:///modules/$module_name/config-storage-live-migration.sh"
            }
            ->
            exec { "setup-config-storage-live-migration":
                  command => "/etc/contrail/contrail_setup_utils/config-storage-live-migration.sh $serverip \
                             $contrail_live_migration_host $contrail_storage_num_osd $contrail_openstack_ip \
                             $contrail_live_migration_ip" ,
                  provider => shell,
                  timeout => 0,
                  logoutput => $contrail_logoutput
            }
            Exec['setup-config-storage-openstack'] -> Exec['setup-config-storage-live-migration']
            Exec['setup-config-storage-live-migration']-> Contrail::Lib::Report_status['storage-master_completed']
        }
    }

    if 'compute' in $contrail_host_roles {
        Ceph::Key<| title == 'client.bootstrap-osd' |> -> Exec['setup-config-storage-compute']
        file { "config-storage-compute.sh":
            ensure  => present,
            path => "/etc/contrail/contrail_setup_utils/config-storage-compute.sh",
            mode => 0755,
            owner => root,
            group => root,
            source => "puppet:///modules/$module_name/config-storage-compute.sh"
        }
        -> 
        exec { "setup-config-storage-compute" :
            command => "/etc/contrail/contrail_setup_utils/config-storage-compute.sh \
                    ${contrail_storage_virsh_uuid} ${contrail_openstack_ip} \
                    && echo setup-config-storage-compute \
                    >> /etc/contrail/contrail-storage-exec.out" ,
            require => File["config-storage-compute.sh"],
            unless  => "grep -qx setup-config-storage-compute /etc/contrail/contrail-storage-exec.out",
            provider => shell,
            logoutput => $contrail_logoutput
        }

        Exec['setup-config-storage-compute']-> Contrail::Lib::Report_status['storage-compute_completed']

        if $contrail_live_migration_host != '' {
          file { "config-storage-lm-compute.sh":
              path => '/etc/contrail/contrail_setup_utils/config-storage-lm-compute.sh',
              ensure  => present,
              mode => 0755,
              owner => root,
              group => root,
              source => "puppet:///modules/$module_name/config-storage-lm-compute.sh"
          }
          ->
          file { "openstack-get-config":
              path => '/etc/contrail/contrail_setup_utils/openstack-get-config',
              ensure  => present,
              mode => 0755,
              owner => root,
              group => root,
              source => "puppet:///modules/$module_name/openstack-get-config"
          } ->
          exec { "setup-config-storage-compute-live-migration":
              command => "/etc/contrail/contrail_setup_utils/config-storage-lm-compute.sh \
                         $contrail_live_migration_host $contrail_lm_storage_scope \
                         $contrail_live_migration_ip" ,
              provider => shell,
              timeout => 0,
              logoutput => $contrail_logoutput
          }
          Exec['setup-config-storage-compute'] -> Exec['setup-config-storage-compute-live-migration']
          Exec['setup-config-storage-compute-live-migration']-> Contrail::Lib::Report_status['storage-compute_completed']
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
        unless  => "/usr/bin/virsh secret-get-value ${contrail_storage_virsh_uuid} ",
        require => Exec['ceph-virsh-secret']
    }
    ->
    file { '/etc/ceph/virsh.conf':
        ensure => present,
        content => "hello new secret : ${contrail_storage_virsh_uuid}",
    }
    ->
    service { "ceph-virsh" :
        ## Currently only Ubuntu is supported 
        name => 'libvirt-bin',
        ensure   => running,
        provider => 'init',
        hasrestart => 'true',
        hasstatus => 'true',
        require  => Exec['ceph-virsh-secret'],
        subscribe => File['/etc/ceph/virsh.conf'],
    }
    ->
    contrail::lib::report_status { "storage-master_completed": state => "storage-master_completed" }
    contrail::lib::report_status { "storage-compute_completed": state => "storage-compute_completed" }
}


