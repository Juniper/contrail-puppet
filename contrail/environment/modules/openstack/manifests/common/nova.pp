# Common class for nova installation
# Private, and should not be used on its own
# usage: include from controller, declare from worker
# This is to handle dependency
# depends on openstack::profile::base having been added to a node
class openstack::common::nova ($is_compute    = false) {
  $is_controller = $::openstack::profile::base::is_controller
  $sync_db = $::contrail::params::sync_db


  $management_network = $::openstack::config::network_management
  $management_address = ip_for_network($management_network)

  $storage_management_address = $::openstack::config::storage_address_management
  $controller_management_address = $::openstack::config::controller_address_management
  $internal_vip = $::contrail::params::internal_vip
  if ($internal_vip != "" and $internal_vip != undef) {
    $contrail_rabbit_port = "5673"
    $contrail_rabbit_host = $controller_management_address
    $contrail_neutron_server = $controller_management_address
  } else {
    $contrail_rabbit_port = "5672"
    $contrail_rabbit_host = $::contrail::params::config_ip_list[0]
    $contrail_neutron_server = $::contrail::params::config_ip_list[0]
  }


  class { '::nova':
    sql_connection     => $::openstack::resources::connectors::nova,
    glance_api_servers => "http://${storage_management_address}:9292",
    memcached_servers  => ["${controller_management_address}:11211"],
    rabbit_hosts       => [$contrail_rabbit_host],
    rabbit_userid      => $::openstack::config::rabbitmq_user,
    rabbit_password    => $::openstack::config::rabbitmq_password,
    debug              => $::openstack::config::debug,
    verbose            => $::openstack::config::verbose,
    mysql_module       => '2.2',
    rabbit_port        => $contrail_rabbit_port,
    notification_driver => "nova.openstack.common.notifier.rpc_notifier",
  }
  nova_config { 'DEFAULT/rabbit_port':
     value => $contrail_rabbit_port,
  }
  nova_config { 'DEFAULT/default_floating_pool': value => 'public' }

  if ($internal_vip != "" and $internal_vip != undef) {
    nova_config {
      'DEFAULT/osapi_compute_listen_port':     value => '9774';
      'DEFAULT/metadata_listen_port':     value => '9775';
    }
    class { '::nova::api':
      admin_password                       => $::openstack::config::nova_password,
      auth_host                            => $controller_management_address,
      enabled                              => $is_controller,
      sync_db                              => $sync_db,
      neutron_metadata_proxy_shared_secret => $::openstack::config::neutron_shared_secret,
      osapi_compute_workers                => '40'
    }

    class { '::nova::vncproxy':
      host    => $::openstack::config::controller_address_api,
      enabled => $is_controller,
      port => '6999',
    }


  } else {
    class { '::nova::api':
      admin_password                       => $::openstack::config::nova_password,
      auth_host                            => $controller_management_address,
      enabled                              => $is_controller,
      sync_db                              => $sync_db,
      neutron_metadata_proxy_shared_secret => $::openstack::config::neutron_shared_secret,
    }

    class { '::nova::vncproxy':
      host    => $::openstack::config::controller_address_api,
      enabled => $is_controller,
    }

  }

  class { [
    'nova::scheduler',
    'nova::objectstore',
#   'nova::cert',
    'nova::consoleauth',
    'nova::conductor'
  ]:
    enabled => $is_controller,
  }

  # TODO: it's important to set up the vnc properly
  class { '::nova::compute':
    enabled                       => $is_compute,
    vnc_enabled                   => true,
    vncserver_proxyclient_address => $management_address,
    vncproxy_host                 => $::openstack::config::controller_address_api,
  }

  class { '::nova::compute::neutron':
    libvirt_vif_driver => "nova_contrail_vif.contrailvif.VRouterVIFDriver"
  }


  class { '::nova::network::neutron':
    neutron_admin_password => $::openstack::config::neutron_password,
    neutron_region_name    => $::openstack::config::region,
    #neutron_admin_auth_url => "http://${controller_management_address}:35357/v2.0",
    neutron_admin_auth_url => "http://${contrail_neutron_server}:35357/v2.0",
    neutron_url            => "http://${contrail_neutron_server}:9696",
    vif_plugging_is_fatal  => false,
    vif_plugging_timeout   => '0',
  }
  
}
