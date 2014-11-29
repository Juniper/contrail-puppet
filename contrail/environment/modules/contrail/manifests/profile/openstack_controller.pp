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
    contain ::contrail::profile::openstack::neutron::server 
}
