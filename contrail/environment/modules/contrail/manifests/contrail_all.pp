class contrail::contrail_all() {
    stage{'contrail':}->stage{'provision_start':}->stage{'base':}->stage{'common':}->stage{'keepalived':}->stage{'haproxy':}->stage{'database':}->stage{'webui':}->stage{'openstack':}->stage{'ha_config':}->stage{'config':}->stage{'controller':}->stage{'collector':}->stage{'compute':}->stage{'provision_complete':}
    class { '::contrail' : stage => 'contrail' }
    $host_roles = $contrail::params::host_roles
    class { '::contrail::provision_start' : state => 'provision_started', stage => 'provision_start' }
    class { '::sysctl::base' : stage => 'base' }
    class { '::apt' : stage => 'common' }
    class { '::contrail::profile::common' : stage => 'common' }
    class { '::contrail::profile::keepalived' : stage => 'keepalived' }
    class { '::contrail::profile::haproxy' : stage => 'haproxy' }
    class { '::contrail::profile::database' : stage => 'database' }
    class { '::contrail::profile::webui' : stage => 'webui' }
    class { '::contrail::profile::openstack_controller' : stage => 'openstack' }
    class { '::contrail::ha_config' : stage => 'ha_config' }
    class { '::contrail::profile::config' : stage => 'config' }
    class { '::contrail::profile::controller' : stage => 'controller' }
    class { '::contrail::profile::collector' : stage => 'collector' }
    class { '::contrail::profile::compute' : stage => 'compute' }
    class { '::contrail::provision_complete' : state => 'post_provision_completed', stage => 'provision_complete' }
    if 'tsn' in $host_roles {
       stage{'tsn':}
       class { '::contrail::profile::tsn' : stage => 'tsn'}
       Stage['compute']->Stage['tsn']->Stage['provision_complete']
    }
    if 'toragent' in $host_roles {
       stage{'toragent':}
       class { '::contrail::profile::toragent' : stage => 'toragent' }
       Stage['compute']->Stage['toragent']->Stage['provision_complete']
    }
    if 'storage-master' in $host_roles or 'storage-compute' in $host_roles {
       stage{'storage':}
       class { '::contrail::profile::storage' : stage => 'storage' }
       Stage['compute']->Stage['storage']->Stage['provision_complete']
    }
}
