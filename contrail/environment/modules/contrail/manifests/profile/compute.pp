class contrail::profile::compute {
    require ::contrail::common
    require ::openstack::profile::firewall
    require ::contrail::profile::nova::compute
#   require ::openstack::profile::ceilometer::agent
}

