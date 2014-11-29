# The profile for installing the Cinder API
class openstack::profile::cinder::api {

  openstack::resources::controller { 'cinder': }
  openstack::resources::database { 'cinder': }
  openstack::resources::firewall { 'Cinder API': port => '8776', }

  include ::openstack::common::cinder

  class { '::cinder::api':
    keystone_password  => $::openstack::config::cinder_password,
    keystone_auth_host => $::openstack::config::controller_address_management,
    enabled            => true,
  }

  class { '::cinder::scheduler':
    scheduler_driver => 'cinder.scheduler.simple.SimpleScheduler',
    enabled          => true,
  }
}
