class openstack::role::contrail::controller {
    stage { 'contrail_common':}
    stage { 'first': }
    stage { 'last': }
    Stage['contrail_common']->Stage['first']->Stage['main']-> Stage['last']
    class { '::contrail::common' : 
        stage => 'contrail_common'
    }
    class { '::openstack::profile::contrail::keepalived':
        #vip => "${::contrail::config::internal_vip}/${::contrail::config::contrail_cidr}",
        #interface => "${::contrail::common::physical_interface}",
        #state => "${::openstack::config::contrail::vrrp_state}",
        vip => "10.84.51.100/24",
        interface => "eth1",
        state => "MASTER",
    }
    include ::openstack::profile::contrail::haproxy
    include ::openstack::profile::base
    include ::openstack::profile::contrail::database
    include ::openstack::profile::contrail::webui
    include ::openstack::profile::contrail::openstack_controller
    include ::openstack::profile::contrail::config
}
