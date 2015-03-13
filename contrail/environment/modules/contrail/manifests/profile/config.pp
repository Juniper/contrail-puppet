# The puppet module to set up a Contrail Config server
class contrail::profile::config {

    contain ::contrail::config
    #contrail expects neutron server to run on configs
    include ::contrail::profile::neutron_server
}
