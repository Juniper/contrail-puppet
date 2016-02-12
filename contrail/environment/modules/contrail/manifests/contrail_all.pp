class contrail::contrail_all() {

    include ::contrail
    $host_roles = $contrail::params::host_roles

    stage { 'first': }
    stage { 'last': }
    stage { 'compute': }
    stage { 'pre': }
    stage { 'post': }

    Stage['pre']->Stage['first']->Stage['main']->Stage['last']->Stage['compute']->Stage['post']
    if 'tsn' in $host_roles {
       stage { 'tsn': }
       Stage['compute'] -> Stage['tsn'] -> Stage['post']
       class { '::contrail::profile::tsn' :  stage => 'tsn' }
    }
    if 'toragent' in $host_roles {
       stage { 'toragent': }
       Stage['compute'] -> Stage['toragent'] -> Stage['post']
       class { '::contrail::profile::toragent' :  stage => 'toragent' }
    }
    if 'storage-master' in $host_roles or 'storage-compute' in $host_roles {
       stage { 'storage': }
       Stage['compute'] -> Stage['storage'] -> Stage['post']
       class { '::contrail::profile::storage' :  stage => 'storage' }
    }
    class { '::contrail::provision_start' : state => 'provision_started', stage => 'pre' }
    class { '::sysctl::base' : stage => 'first' }
    class { '::apt' : stage => 'first' }
    class { '::contrail::profile::common' : stage => 'first' }
    include ::contrail::profile::keepalived
    include ::contrail::profile::haproxy
    include ::contrail::profile::database
    include ::contrail::profile::webui
    include ::contrail::profile::openstack_controller
    include ::contrail::ha_config
    include ::contrail::profile::config
    include ::contrail::profile::controller
    include ::contrail::profile::collector
    class { '::contrail::profile::compute' : stage => 'compute' }
    class { '::contrail::provision_complete' : state => 'post_provision_completed', stage => 'post' }

}
