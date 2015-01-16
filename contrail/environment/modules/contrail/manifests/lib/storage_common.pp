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
        $contrail_storage_mon_hosts,
        $contrail_storage_osd_disks, 
        $contrail_storage_hostname
        ) {

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
	}
	file { "ceph-osd-setup-file":
	    path => "/etc/contrail/contrail_setup_utils/config-storage-add-osd.sh",
	    ensure  => present,
	    mode => 0755,
	    owner => root,
	    group => root,
	    source => "puppet:///modules/$module_name/config-storage-add-osd.sh",
	}

	file { "ceph-disk-clean-file":
	    path => "/etc/contrail/contrail_setup_utils/config-storage-disk-clean.sh",
	    ensure  => present,
	    mode => 0755,
	    owner => root,
	    group => root,
	    source => "puppet:///modules/$module_name/config-storage-disk-clean.sh",
	}
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
	if $contrail_num_storage_hosts > 1 {
		$contrail_storage_replica_size = 2
	} else {
		$contrail_storage_replica_size = 1
	}

	class { 'ceph' : 
		fsid => $contrail_storage_fsid,
		mon_host => "$contrail_storage_mon_hosts",
		keyring => '/etc/ceph/$cluster.$name.keyring',
		cluster_network => $contrail_storage_cluster_network,
		require => Package['contrail-storage'],
	} ->
	ceph::mon { $contrail_storage_hostname: 
		key => $contrail_storage_mon_secret
	} -> 
	ceph::key{'client.admin':
		secret => $contrail_storage_admin_key,
		cap_mon => 'allow *',
		cap_osd => 'allow *',
		inject_as_id => 'mon.',
		inject_keyring => "/var/lib/ceph/mon/ceph-$hostname/keyring",
		inject => true,
	 } ->

	 ceph::key{'client.bootstrap-osd':
		secret => $contrail_storage_osd_bootstrap_key,
		cap_mon => 'profile bootstrap-osd',
		inject_as_id => 'mon.',
		inject_keyring => "/var/lib/ceph/mon/ceph-$hostname/keyring",
		inject => true,
	  }

	if $contrail_storage_osd_disks != 'undef' {
		$contrail_ceph_pg_num = 32 * $contrail_storage_num_osd
		Ceph::Osd<| |> -> Ceph::Pool['volumes']
		Ceph::Osd<| |> -> Ceph::Pool['images']
		contrail::lib::prepare_disk{ $contrail_storage_osd_disks :
		} ->
		ceph::osd { $contrail_storage_osd_disks: 
			require => Contrail::Lib::Prepare_disk[$contrail_storage_osd_disks]
		} -> 
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
	}
	  if 'openstack' in $contrail_host_roles {
		#notify { "role openstack":}
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
	   ## XXX : add logic to call this only after all OSDs are up
	    exec { "setup-config-storage-openstack" :
		command => "/etc/contrail/contrail_setup_utils/config-storage-openstack.sh \
				${contrail_storage_virsh_uuid} ${contrail_openstack_ip} $contrail_storage_num_osd \
				&& echo setup-config-storage-openstack \
				>> /etc/contrail/contrail-storage-exec.out" ,
		require => File["config-storage-openstack.sh"],
		unless  => "grep -qx setup-config-storage-openstack /etc/contrail/contrail-storage-exec.out",
		provider => shell,
		logoutput => "true"
	    }

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
                           $contrail_live_migration_host $contrail_storage_num_osd" ,
		provider => shell,
                timeout => 0,
		logoutput => "true"
            }
	    Exec['setup-config-storage-openstack'] -> Exec['setup-config-storage-live-migration']
            }
	  }
	  

	  if 'compute' in $contrail_host_roles {
	    Ceph::Key<| title == 'client.bootstrap-osd' |> -> Exec['setup-config-storage-compute']
	    file { "config-storage-compute.sh":
		ensure  => present,
		mode => 0755,
		owner => root,
		group => root,
		#require => Package["contrail-openstack-config"],
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
		logoutput => "true"
	    }

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
                           $contrail_live_migration_host $contrail_live_migration_storage_scope" ,
		provider => shell,
                timeout => 0,
		logoutput => "true"
            }
	  Exec['setup-config-storage-compute'] -> Exec['setup-config-storage-compute-live-migration']
	  }
     }

	Ceph::Key<| title == 'client.bootstrap-osd' |> -> Exec['ceph-volumes-key']
	Ceph::Key<| title == 'client.bootstrap-osd' |> -> Exec['ceph-images-key']

  exec { 'ceph-volumes-key':
    command => "/usr/bin/ceph auth get-or-create client.volumes mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images' -o /etc/ceph/ceph.client.volumes.keyring",
    creates => '/etc/ceph/ceph.client.volumes.keyring',
  }
  ->
  exec { 'ceph-images-key':
    command => "/usr/bin/ceph auth get-or-create client.images mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images' -o /etc/ceph/ceph.client.images.keyring",
    creates => '/etc/ceph/ceph.client.images.keyring',
  }
  ->
  exec { 'ceph-virsh-secret' : 
    command => "/bin/echo '<secret ephemeral=\"no\" private=\"no\"><uuid>${contrail_storage_virsh_uuid}</uuid><usage type=\"ceph\"><name>client.volumes secret</name></usage></secret>' > secret.xml && /usr/bin/virsh secret-define --file secret.xml && /bin/rm secret.xml",
    unless  => "/usr/bin/virsh secret-list | grep -q ${contrail_storage_virsh_uuid}",
    require => Exec['ceph-volumes-key']
  }
  -> 
  exec { 'ceph-virsh-set-secret' : 
    command => "/usr/bin/virsh secret-set-value ${contrail_storage_virsh_uuid} --base64 `/usr/bin/ceph auth get client.volumes  | grep \"key = \" | awk '{printf \$3}'`", 
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
}
