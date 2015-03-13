class openstack::resources::connectors {
  $internal_vip = $::contrail::params::internal_vip

  $management_address = $::openstack::config::controller_address_management


  if ($internal_vip != "" and $internal_vip != undef) {
    $mysql_port = "33306"
    $management_ip_address = $::openstack::config::controller_address_management 
    $nova_management_address = "${management_ip_address}:${mysql_port}"
  } else { 
    $nova_management_address = $::openstack::config::controller_address_management
  }

  $password = $::openstack::config::mysql_service_password

  $keystone = "mysql://keystone:${password}@${management_address}/keystone"
  $cinder   = "mysql://cinder:${password}@${management_address}/cinder"
  $glance   = "mysql://glance:${password}@${management_address}/glance"
  $nova     = "mysql://nova:${password}@${nova_management_address}/nova"
  $neutron  = "mysql://neutron:${password}@${management_address}/neutron"
  $heat     = "mysql://heat:${password}@${management_address}/heat"
}
