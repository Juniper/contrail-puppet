# The profile to set up the Nova controller (several services)
class openstack::profile::nova::api {
  openstack::resources::controller { 'nova': }
  openstack::resources::database { 'nova': }
  openstack::resources::firewall { 'Nova API': port => '8774', }
  openstack::resources::firewall { 'Nova Metadata': port => '8775', }
  openstack::resources::firewall { 'Nova EC2': port => '8773', }
  openstack::resources::firewall { 'Nova S3': port => '3333', }
  openstack::resources::firewall { 'Nova novnc': port => '6080', }

  $host_ip = hiera(contrail::params::host_ip)
  $compute_ip_list = hiera(contrail::params::compute_ip_list)

  $tmp_index = inline_template('<%= @compute_ip_list.index(@host_ip) %>')
  notify { "openstack::common::nova - compute_ip_list = $compute_ip_list":;}
  notify { "openstack::common::nova - host_ip = $host_ip":;}

  if ($tmp_index != nil and $tmp_index != undef and $tmp_index != "" ) {
    $contrail_is_compute = true
  } else {
    $contrail_is_compute = false
  }
  notify { "openstack::common::nova -contrail_is_compute  = $contrail_is_compute":;}
  notify { "openstack::common::nova - tmp_index = X$tmp_index X":;}
  notify { "openstack::common::nova - controller_management_address = $controller_management_address":; }

  class { '::openstack::common::nova' :
         is_compute => $contrail_is_compute,
  }
}
