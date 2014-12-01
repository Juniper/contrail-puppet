# The puppet module to set up a openstack controller
class openstack::profile::contrail::openstack_controller {
    include ::openstack::profile::base
    include ::openstack::profile::firewall
    include ::openstack::profile::contrail::mysql
    include ::openstack::profile::keystone
    include ::openstack::profile::memcache
    include ::openstack::profile::contrail::glance::api
    include ::openstack::profile::cinder::api
    include ::openstack::profile::nova::api
    include ::openstack::profile::horizon
    include ::openstack::profile::auth_file
    class { '::openstack::profile::contrail::neutron::server': 
        stage => 'last'
    }
}
