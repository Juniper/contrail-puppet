class contrail::contrail_all() {
    contain ::contrail
    $host_roles = $contrail::params::host_roles
    class { '::contrail::provision_start' : state => 'provision_started' }
    contain ::contrail::provision_start
    contain ::sysctl::base
    contain ::apt
    contain ::contrail::profile::common
    contain ::contrail::profile::keepalived
    contain ::contrail::profile::haproxy
    contain ::contrail::profile::database
    contain ::contrail::profile::webui
    contain ::contrail::profile::openstack_controller
    contain ::contrail::ha_config
    contain ::contrail::profile::config
    contain ::contrail::profile::controller
    contain ::contrail::profile::collector
    contain ::contrail::profile::compute
    class { '::contrail::provision_complete' : state => 'post_provision_completed' }
    contain ::contrail::provision_complete
    Class['::contrail']->Class['::contrail::provision_start']->Class['::sysctl::base']->Class['::contrail::profile::common']->Class['::contrail::profile::keepalived']->Class['::contrail::profile::haproxy']->Class['::contrail::profile::database']->Class['::contrail::profile::webui']->Class['::contrail::profile::openstack_controller']->Class['::contrail::ha_config']->Class['::contrail::profile::config']->Class['::contrail::profile::controller']->Class['::contrail::profile::collector']->Class['::contrail::profile::compute']->Class['::contrail::provision_complete']
}
    if 'tsn' in $host_roles {
       contain ::contrail::profile::tsn
       Class['::contrail::profile::compute']->Class['::contrail::profile::tsn']->Class['::contrail::provision_complete']
    }
    if 'toragent' in $host_roles {
       contain ::contrail::profile::toragent
       Class['::contrail::profile::compute']->Class['::contrail::profile::toragent']->Class['::contrail::provision_complete']
    }
    if 'storage-master' in $host_roles or 'storage-compute' in $host_roles {
       contain ::contrail::profile::storage
       Class['::contrail::profile::compute']->Class['::contrail::profile::storage']->Class['::contrail::provision_complete']
    }
