# The profile to install a local instance of memcache
class openstack::profile::memcache {
  class { 'memcached':
    tcp_port  => '11211',
    udp_port  => '11211',
  }
}
