define contrail::post_provision(
  $nova_public_key  = $contrail::params::nova_public_key,
  $nova_private_key = $contrail::params::nova_private_key,
  $host_roles       = $contrail::params::host_roles,
  $user_nova_config = $::contrail::params::user_nova_config,
  $user_glance_config   = $::contrail::params::user_glance_config,
  $user_cinder_config   = $::contrail::params::user_cinder_config,
  $user_keystone_config = $::contrail::params::user_keystone_config,
  $user_neutron_config  = $::contrail::params::user_neutron_config,
  $user_heat_config     = $::contrail::params::user_heat_config,
  $user_ceilometer_config = $::contrail::params::user_ceilometer_config,
  $user_ceph_config     = $::contrail::params::user_ceph_config,
) {
  file { '/var/lib/nova/.ssh':
    ensure  => directory,
    mode    => '0700',
    group   => nova,
    owner   => nova,
  } ->
  file {'/var/lib/nova/.ssh/config':
    ensure  => present,
    mode    => '0600',
    content => "Host *\r\n StrictHostKeyChecking no\r\n UserKnownHostsFile=/dev/null",
    group   => nova,
    owner   => nova,
  } ->
  file {'/var/lib/nova/.ssh/id_rsa':
    ensure  => present,
    mode    => '0600',
    content => "$nova_private_key",
    group   => nova,
    owner   => nova,
  } ->
  file {'/var/lib/nova/.ssh/id_rsa.pub':
    ensure  => present,
    mode    => '0600',
    content => "$nova_public_key",
    group   => nova,
    owner   => nova,
  } ->
  file {'/var/lib/nova/.ssh/authorized_keys':
    ensure  => present,
    mode    => '0600',
    content => "$nova_public_key",
    group   => nova,
    owner   => nova,
  }

  if 'compute' in $host_roles {
    create_resources(nova_config, $user_nova_config['config'] )
  }

  if 'openstack' in $host_roles {
    create_resources(nova_config, $user_nova_config['config'] )
    create_resources(glance_config, $user_glance_config['config'] )
    create_resources(cinder_config, $user_cinder_config['config'] )
    create_resources(keystone_config, $user_keystone_config['config'] )
    #create_resources(neutron_config, $user_neutron_config['config'] )
  }
  if 'storage-master' in $host_roles or 'storage-compute' in $host_roles {
    create_resources(ceph_config, $user_ceph_config['config'] )
  }
}
