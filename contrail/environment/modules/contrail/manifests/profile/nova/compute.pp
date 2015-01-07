# The puppet module to set up a Nova Compute node
class contrail::profile::nova::compute {
    #include ::openstack::common::neutron

    $controller_management_address = hiera(openstack::controller::address::management)
    notify { "contrail::profile::nova::compute - controller_management_address = $controller_management_address":; }
    include contrail::compute
}
