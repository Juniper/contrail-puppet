# The puppet module to set up a openstack controller
class contrail::profile::neutron_server {
  #contain ::openstack::profile::base
  contain ::contrail::profile::neutron::server
  #Class['::contrail::profile::openstack::mysql']->Class['::contrail::profile::neutron::server']
}
