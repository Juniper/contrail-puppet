class contrail::compute::add_dev_tun_in_cgroup_device_acl (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    file { '/etc/contrail/contrail_setup_utils/add_dev_tun_in_cgroup_device_acl.sh':
            ensure => present,
            mode   => '0755',
            owner  => root,
            group  => root,
            source => "puppet:///modules/${module_name}/add_dev_tun_in_cgroup_device_acl.sh"
    } ->
    exec { 'add_dev_tun_in_cgroup_device_acl' :
            command   => './add_dev_tun_in_cgroup_device_acl.sh && echo add_dev_tun_in_cgroup_device_acl >> /etc/contrail/contrail_compute_exec.out',
            cwd       => '/etc/contrail/contrail_setup_utils/',
            unless    => 'grep -qx add_dev_tun_in_cgroup_device_acl /etc/contrail/contrail_compute_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
    }
    ->
    notify { "executed add_dev_tun_in_cgroup_device_acl" :; }
}
