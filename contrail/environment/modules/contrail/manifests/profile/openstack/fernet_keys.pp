class contrail::profile::openstack::fernet_keys (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $openstack_ip = $openstack_ip
) {
    $opts = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
    # Copy /etc/keystone/fernet-keys/ from first openstack node
    exec{ 'sync_fernet_keys':
      command => "rsync -arvce \"${opts}\" root@${openstack_ip}:/etc/keystone/fernet-keys /etc/keystone/",
      provider => shell,
      logoutput => $contrail_logoutput
    }
}
