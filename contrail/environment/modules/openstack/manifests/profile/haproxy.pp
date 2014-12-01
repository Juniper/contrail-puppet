# Profile to install the haproxy
class openstack::profile::haproxy {
  class { '::haproxy':}
}
