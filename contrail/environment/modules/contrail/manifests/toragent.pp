class contrail::toragent(
    $config_ip = $::contrail::params::config_ip_list[0],
    $contrail_tsn_ip = $::contrail::params::tsn_ip_list[0],
    $contrail_tsn_hostname = $::contrail::params::tsn_name_list[0],
    $contrail_openstack_ip = $::contrail::params::openstack_ip_list[0],
    $internal_vip = $::contrail::params::internal_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $haproxy = $::contrail::params::haproxy,
) {
    # Set config IP to be used.
    if ($contrail_internal_vip != "") {
        $config_ip_to_use = $contrail_internal_vip
    }
    elsif ($internal_vip != "") {
        $config_ip_to_use = $internal_vip
    }
    else {
        $config_ip_to_use = $config_ip
    }
    if ($haproxy == true) {
        $discovery_ip = "127.0.0.1"
    } else {
        $discovery_ip = $config_ip_to_use
    }

   $tor_defaults  = {
      'discovery_ip_to_use' => $discovery_ip,
      'contrail_tsn_ip' => $contrail_tsn_ip,
      'contrail_tsn_hostname' => $contrail_tsn_hostname,
      'contrail_config_ip' => $config_ip_to_use,
      'keystone_admin_user' => $keystone_admin_user,
      'keystone_admin_password' => $keystone_admin_password,
      'keystone_admin_tenant' => $keystone_admin_tenant,
      'contrail_openstack_ip' => $contrail_openstack_ip 
    }
   contrail::lib::report_status { "toragent_started": state => "toragent_started" }
   $tor_config = hiera('contrail::params::top_of_rack', {})
   create_resources(contrail::lib::top_of_rack, $tor_config, $tor_defaults)
   contrail::lib::report_status { "toragent_completed": state => "toragent_completed" }

  Contrail::Lib::Report_status['toragent_started']
  -> Contrail::Lib::Top_of_rack <| |>
  -> Contrail::Lib::Report_status['toragent_completed']
}
