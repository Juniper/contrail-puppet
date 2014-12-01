# The puppet module to set up a Contrail WebUI server
class openstack::profile::contrail::keepalived(
        $state,
        $vip,
        $interface = 'eth1') {
    include ::keepalived

    keepalived::vrrp::script { 'check_haproxy':
      script => '/usr/bin/killall -0 haproxy',
    }

    keepalived::vrrp::instance { 'VI_50':
      interface         => $interface,
      state             => $state,
      virtual_router_id => '51',
      priority          => '101',
      auth_type         => 'PASS',
      auth_pass         => 'secret',
      virtual_ipaddress => $vip,
      track_script      => 'check_proxy',
    }
}
