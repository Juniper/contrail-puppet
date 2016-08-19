class contrail::compute::create_nfs (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    file { ['/var/tmp', '/var/tmp/glance-images']:
           ensure => directory,
           mode   => '0777'
    } ->
    exec { 'create-nfs' :
           command   => 'echo \"/var/tmp/glance-images *(rw,sync,no_subtree_check)\" >> /etc/exports && echo create-nfs >> /etc/contrail/contrail_compute_exec.out ',
           unless    => 'grep -qx create-nfs  /etc/contrail/contrail_compute_exec.out',
           provider  => shell,
           logoutput => $contrail_logoutput
    }
    ->
    notify { "executed create_nfs" :; }
}
