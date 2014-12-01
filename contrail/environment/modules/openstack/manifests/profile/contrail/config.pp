# The puppet module to set up a Contrail Config server
class openstack::profile::contrail::config {
    # contrail-config role.
    require ::openstack::profile::contrail::keepalived
    require ::openstack::profile::contrail::haproxy
    require ::openstack::profile::keystone
    include ::contrail::config
}
