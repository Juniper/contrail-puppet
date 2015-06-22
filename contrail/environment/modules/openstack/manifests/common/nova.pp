# Common class for nova installation
# Private, and should not be used on its own
# usage: include from controller, declare from worker
# This is to handle dependency
# depends on openstack::profile::base having been added to a node
class openstack::common::nova ($is_compute    = false) {
  $is_controller = $::openstack::profile::base::is_controller
  $sync_db = $::contrail::params::sync_db
  $enable_ceilometer = $::contrail::params::enable_ceilometer

  $management_network = $::openstack::config::network_management
  $management_address = ip_for_network($management_network)

  $storage_management_address = $::openstack::config::storage_address_management
  $controller_management_address = $::openstack::config::controller_address_management
  $internal_vip = $::contrail::params::internal_vip
  $contrail_internal_vip = $::contrail::params::contrail_internal_vip

  $contrail_rabbit_host = $::contrail::params::config_ip_to_use
  $contrail_rabbit_port = $::contrail::params::contrail_rabbit_port
  $contrail_neutron_server = $::contrail::params::config_ip_to_use

  $openstack_ip_list = $::contrail::params::openstack_ip_list
  $contrail_memcache_servers = inline_template('<%= @openstack_ip_list.map{ |ip| "#{ip}:11211" }.join(",") %>')

  nova_config { 'DEFAULT/rabbit_port':
     value => $contrail_rabbit_port,
  } ->
  nova_config { 'DEFAULT/default_floating_pool': value => 'public' }
  ->
  nova_config { 'conductor/workers':
       value => '40',
       notify => Service['nova-api']
  }

  if ($enable_ceilometer) {
     $notify_on_state_change = 'vm_and_task_state'
  } else {
    $notify_on_state_change = ''
  }

  if ($internal_vip != "" and $internal_vip != undef) {
    class { '::nova':
      sql_connection     => $::openstack::resources::connectors::nova,
      glance_api_servers => "http://${storage_management_address}:9292",
      memcached_servers  => ["$contrail_memcache_servers"],
      rabbit_hosts       => [$contrail_rabbit_host],
      rabbit_userid      => $::openstack::config::rabbitmq_user,
      rabbit_password    => $::openstack::config::rabbitmq_password,
      debug              => $::openstack::config::debug,
      verbose            => $::openstack::config::verbose,
      mysql_module       => '2.2',
      rabbit_port        => $contrail_rabbit_port,
      database_idle_timeout => '180',
      notification_driver => "nova.openstack.common.notifier.rpc_notifier",
    }

    nova_config {
      'DEFAULT/osapi_compute_listen_port':     value => '9774';
      'DEFAULT/metadata_listen_port':          value => '9775';
      'DEFAULT/scheduler_max_attempts':        value => '10';
      'DEFAULT/disable_process_locking':       value => 'True';
      'DEFAULT/rabbit_retry_interval':         value => '1';
      'DEFAULT/rabbit_retry_backoff':          value => '2';
      'DEFAULT/rabbit_max_retries':            value => '0';
      'DEFAULT/rabbit_interval':               value => '15';
      'database/min_pool_size':                value => '100';
      'database/max_pool_size':                value => '350';
      'database/max_overflow':                 value => '700';
      'database/retry_interval':               value => '5';
      'database/max_retries':                  value => '-1';
      'database/db_max_retries':               value => '3';
      'database/db_retry_interval':            value => '1';
      'database/connection_debug':             value => '10';

    }
    ->
    nova_config {'DEFAULT/pool_timeout':
       value => '120',
       notify => Service['nova-api']
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

    class { '::nova':
      sql_connection     => $::openstack::resources::connectors::nova,
      glance_api_servers => "http://${storage_management_address}:9292",
      memcached_servers  => ["$contrail_memcache_servers"],
      rabbit_hosts       => [$contrail_rabbit_host],
      rabbit_userid      => $::openstack::config::rabbitmq_user,
      rabbit_password    => $::openstack::config::rabbitmq_password,
      debug              => $::openstack::config::debug,
      verbose            => $::openstack::config::verbose,
      mysql_module       => '2.2',
      rabbit_port        => $contrail_rabbit_port,
      notification_driver => "nova.openstack.common.notifier.rpc_notifier",
      notify_on_state_change => $notify_on_state_change,
    }

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

  # nova-compute is managed by contrail,is_compute flag only disables the service,
  # It still declares the nova-compute service,leading to 1435692.
  /*
  class { '::nova::compute':
    enabled                       => $is_compute,
    vnc_enabled                   => true,
    vncserver_proxyclient_address => $management_address,
    vncproxy_host                 => $::openstack::config::controller_address_api,
  }
  */

  class { '::nova::compute::neutron':
    libvirt_vif_driver => "nova_contrail_vif.contrailvif.VRouterVIFDriver"
  }


  class { '::nova::network::neutron':
    neutron_admin_password => $::openstack::config::neutron_password,
    neutron_region_name    => $::openstack::config::region,
    neutron_admin_auth_url => "http://${controller_management_address}:35357/v2.0",
    neutron_url            => "http://${contrail_neutron_server}:9696",
    vif_plugging_is_fatal  => false,
    vif_plugging_timeout   => '0',
  }

  if ($enable_ceilometer) {
    file_line_after {
      'nova-notification-driver-common':
        line   =>
          'notification_driver=nova.openstack.common.notifier.rpc_notifier',
        path   => '/etc/nova/nova.conf',
        after  => '^\s*\[DEFAULT\]';
      'nova-notification-driver-ceilometer':
        line   => 'notification_driver=ceilometer.compute.nova_notifier',
        path   => '/etc/nova/nova.conf',
        after  => '^\s*\[DEFAULT\]';
    }
  }

}
