define contrail::post_provision(
  $nova_public_key = $contrail::params::nova_public_key,
  $nova_private_key = $contrail::params::nova_private_key,
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
}
