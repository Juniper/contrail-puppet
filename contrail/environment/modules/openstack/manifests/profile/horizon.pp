# Profile to install the horizon web service
class openstack::profile::horizon {
  $internal_vip = $::contrail::params::internal_vip
  $external_vip =  $::contrail::params::external_vip
  if ($internal_vip != "" and $internal_vip != undef) {

    $contrail_keystone_url = "http://${internal_vip}:5000/v2.0"
  } else {

    $contrail_keystone_url = "http://127.0.0.1:5000/v2.0"
  }

 
  class { '::horizon':
    fqdn            => [ '127.0.0.1', $::openstack::config::controller_address_api, $::fqdn, $external_vip ],
    secret_key      => $::openstack::config::horizon_secret_key,
    cache_server_ip => $::openstack::config::controller_address_management,
    keystone_url => $contrail_keystone_url

  }

  openstack::resources::firewall { 'Apache (Horizon)': port => '80' }
  openstack::resources::firewall { 'Apache SSL (Horizon)': port => '443' }

  if $::selinux and str2bool($::selinux) != false {
    selboolean{'httpd_can_network_connect':
      value      => on,
      persistent => true,
    }
  }

}
