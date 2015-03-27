# The puppet module to set up a openstack controller
class contrail::profile::openstack_controller {
    contrail::lib::report_status { "openstack_started": state => "openstack_started" } ->
    class {'::openstack::profile::base' : } ->
    class {'::openstack::profile::firewall' : } ->
    class {'::contrail::profile::openstack::mysql' : } ->
    class {'::openstack::profile::keystone' : } ->
    class {'::openstack::profile::memcache' : } ->
    class {'::contrail::profile::openstack::glance::api' : } ->
    class {'::openstack::profile::cinder::api' : } ->
    class {'::openstack::profile::nova::api' : } ->
    class {'::openstack::profile::horizon' : } ->
    class {'::openstack::profile::auth_file' : } ->
    class {'::openstack::profile::provision' : } ->
    #Contrail expects neutron to run on config nodes only
    class {'::contrail::profile::openstack::neutron::server' : } ->

    package { 'contrail-openstack-dashboard':
      ensure  => present,
    } ->

    # Though neutron runs on config, setup the db in openstack node 
    exec { 'neutron-db-sync':
        command     => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head',
        path        => '/usr/bin',
        before      => Service['neutron-server'],
        require     => Neutron_config['database/connection'],
        refreshonly => true
    } ->
    class {'::contrail::contrail_openstack' : } ->
    contrail::lib::report_status { "openstack_completed": state => "openstack_completed" }

    Class['::neutron::db::mysql'] -> Exec['neutron-db-sync']
    Class['::openstack::profile::provision']->Service['glance-api']
}
