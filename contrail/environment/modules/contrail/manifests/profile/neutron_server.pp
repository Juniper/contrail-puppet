# The puppet module to set up a openstack controller
class contrail::profile::neutron_server {
    contain ::openstack::profile::base
    contain ::contrail::profile::openstack::mysql
    contain ::contrail::profile::neutron::server

}
