# The puppet module to set up a openstack controller
class contrail::profile::openstack_controller {
    contain ::openstack::profile::base
    contain ::openstack::profile::firewall
    contain ::contrail::profile::openstack::mysql
    contain ::openstack::profile::keystone
    contain ::openstack::profile::memcache
    contain ::contrail::profile::openstack::glance::api
    contain ::openstack::profile::cinder::api
    contain ::openstack::profile::nova::api
    contain ::openstack::profile::horizon
    contain ::openstack::profile::auth_file
    contain ::openstack::profile::provision
    Class['::openstack::profile::provision']->Service['glance-api']
    contain ::contrail::contrail_openstack
    Class['::openstack::profile::provision']->Class['::contrail::contrail_openstack']
    #Contrail expects neutron to run on config nodes only
    contain ::contrail::profile::openstack::neutron::server

    package { 'contrail-openstack-dashboard':
      ensure  => present,
    }


#   Though neutron runs on config, setup the db in openstack node 
    exec { 'neutron-db-sync':
      command     => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head',
      path        => '/usr/bin',
      before      => Service['neutron-server'],
      require     => Neutron_config['database/connection'],
      refreshonly => true
    }

    Class['::neutron::db::mysql'] -> Exec['neutron-db-sync']

}
