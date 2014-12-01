# The puppet module to set up a Contrail Collector Node
class openstack::profile::contrail::collector {
    # contrail-collector role.
    include ::contrail::collector
}
