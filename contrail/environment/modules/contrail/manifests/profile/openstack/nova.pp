class contrail::profile::openstack::nova(
  $host_control_ip   = $::contrail::params::host_ip,
  $internal_vip      = $::contrail::params::internal_vip,
  $nova_password     = $::contrail::params::os_nova_password,
  $neutron_password  = $::contrail::params::os_neutron_password,
  $openstack_verbose = $::contrail::params::os_verbose,
  $openstack_debug   = $::contrail::params::os_debug,
  $region_name       = $::contrail::params::os_region,
  $allowed_hosts     = $::contrail::params::os_mysql_allowed_hosts,
  $rabbitmq_user     = $::contrail::params::os_rabbitmq_user,
  $rabbitmq_password = $::contrail::params::os_rabbitmq_password,
  $sync_db           = $::contrail::params::sync_db,
  $service_password  = $::contrail::params::os_mysql_service_password,
  $address_api       = $::contrail::params::os_controller_api_address ,
  $sriov_enable      = $::contrail::params::sriov_enable,
  $enable_ceilometer = $::contrail::params::enable_ceilometer,
  $package_sku       = $::contrail::params::package_sku,
  $host_roles        = $::contrail::params::host_roles,
  $openstack_ip_list = $::contrail::params::openstack_ip_list,
  $contrail_internal_vip      = $::contrail::params::contrail_internal_vip,
  $openstack_rabbit_servers   = $::contrail::params::openstack_rabbit_hosts,
  $neutron_shared_secret      = $::contrail::params::os_neutron_shared_secret,
  $storage_management_address = $::contrail::params::os_glance_mgmt_address,
  $controller_mgmt_address    = $::contrail::params::os_controller_mgmt_address,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
  $vncproxy_port      = $::contrail::params::vncproxy_port
) {

  $database_credentials = join([$service_password, "@", $host_control_ip],'')
  $auth_uri = "http://${keystone_ip_to_use}:5000/"

  class {'::nova::db::mysql':
    password      => $service_password,
    allowed_hosts => $allowed_hosts,
  }

  if ( $package_sku =~ /^*:13\.0.*$/) {
    ## TODO: Remove once we move to mitaka modules
    class {'::nova::db::mysql_api':
      password      => $service_password,
      allowed_hosts => $allowed_hosts,
    }
  }

  $compute_ip_list = $::contrail::params::compute_ip_list
  $tmp_index = inline_template('<%= @compute_ip_list.index(@host_control_ip) %>')

  if ($tmp_index != nil and $tmp_index != undef and $tmp_index != "" ) {
    $contrail_is_compute = true
  } else {
    $contrail_is_compute = false
  }

  if ($internal_vip != "" and $internal_vip != undef) {
    $neutron_ip_address = $controller_mgmt_address
    $vncproxy_host = $host_control_ip
    $keystone_db_conn = join(["mysql://nova:",$service_password, "@", $internal_vip, ":33306", "/nova"],'')
    $osapi_compute_workers = '40'
    $database_idle_timeout = '180'
  } else {
    $neutron_ip_address = $::contrail::params::config_ip_list[0]
    $vncproxy_host = $address_api
    $keystone_db_conn = join(["mysql://nova:",$database_credentials,"/nova"],'')
    $osapi_compute_workers = $::processorcount
    $database_idle_timeout = '3600'
  }

  $memcache_ip_ports = suffix($openstack_ip_list, ":11211")

  class { '::nova':
    database_connection => $keystone_db_conn,
    glance_api_servers  => "http://${storage_management_address}:9292",
    memcached_servers   => $memcache_ip_ports,
    rabbit_hosts        => $openstack_rabbit_servers,
    rabbit_userid       => $rabbitmq_user,
    rabbit_password     => $rabbitmq_password,
    verbose             => $openstack_verbose,
    debug               => $openstack_debug,
    notification_driver => "nova.openstack.common.notifier.rpc_notifier",
    database_idle_timeout => $database_idle_timeout
  }


  if ($internal_vip != "" and $internal_vip != undef) {
    nova_config {
      'DEFAULT/osapi_compute_listen_port':     value => '9774';
      'DEFAULT/metadata_listen_port':          value => '9775';
      'DEFAULT/scheduler_max_attempts':        value => '10';
      'DEFAULT/disable_process_locking':       value => 'True';
      'DEFAULT/rabbit_retry_interval':         value => '1';
      'DEFAULT/rabbit_retry_backoff':          value => '2';
      'DEFAULT/rabbit_max_retries':            value => '0';
      'DEFAULT/rabbit_interval':               value => '15';
      'DEFAULT/pool_timeout':                  value => '120';
      'database/min_pool_size':                value => '100';
      'database/max_pool_size':                value => '350';
      'database/max_overflow':                 value => '700';
      'database/retry_interval':               value => '5';
      'database/max_retries':                  value => '-1';
      'database/db_max_retries':               value => '3';
      'database/db_retry_interval':            value => '1';
      'database/connection_debug':             value => '10';
    }
  }

  if ($enable_ceilometer) {
    $instance_usage_audit = 'True'
    $instance_usage_audit_period = 'hour'
  }

  class { '::nova::api':
    admin_password                       => $nova_password,
    auth_host                            => $keystone_ip_to_use,
    auth_uri                             => $auth_uri,
    enabled                              => 'true',
    neutron_metadata_proxy_shared_secret => $neutron_shared_secret,
    #sync_db                             => $sync_db,
    sync_db                              => true,
    osapi_compute_workers                => $osapi_compute_workers,
    package_sku                          => $package_sku
  }

  if ( $package_sku =~ /^*:13\.0.*$/) {
    ## TODO: Remove once we move to mitaka modules
    if ($internal_vip != "" and $internal_vip != undef) {
      $nova_api_db_conn = join(["mysql://nova_api:",$service_password, "@", $internal_vip, ":33306", "/nova_api"],'')
    } else {
      $nova_api_db_conn = join(["mysql://nova_api:",$database_credentials,"/nova_api"],'')
    }
    nova_config {
      'api_database/connection': value => $nova_api_db_conn;
      'DEFAULT/use_neutron'    : value => True;
      'neutron/auth_type'      : value => 'password';
      'neutron/project_name'   : value => 'services';
      'neutron/auth_url'       : value => "http://${controller_mgmt_address}:35357";
      'neutron/username'       : value => 'neutron';
      'neutron/password'       : value => $neutron_password;
      'oslo_messaging_rabbit/heartbeat_timeout_threshold' :  value => '0';
    }
  }

  class { '::nova::vncproxy':
    host    => $vncproxy_host,
    enabled => 'true',
    port    => $vncproxy_port,
  }

  class { [
    'nova::scheduler',
    'nova::objectstore',
    'nova::consoleauth',
    'nova::conductor',
  ]:
    enabled => 'true',
  }

  if ('compute' in $host_roles) {
    # TODO: it's important to set up the vnc properly
    class { '::nova::compute':
      enabled                       => $contrail_is_compute,
      vnc_enabled                   => true,
      vncserver_proxyclient_address => $management_address,
      vncproxy_host                 => $address_api,
      instance_usage_audit          => $instance_usage_audit,
      instance_usage_audit_period   => $instance_usage_audit_period
    }

    #TODO make sure we have vif package

    class { '::nova::compute::neutron':
      libvirt_vif_driver => "nova_contrail_vif.contrailvif.VRouterVIFDriver"
    }
  }

  class { '::nova::network::neutron':
    neutron_admin_password => $neutron_password,
    neutron_region_name    => $region_name,
    neutron_admin_auth_url => "http://${keystone_ip_to_use}:35357/v2.0",
    neutron_url            => "http://${neutron_ip_address}:9696",
    vif_plugging_is_fatal  => false,
    vif_plugging_timeout   => '0',
  }

  if ($sriov_enable) {
    file_line_after {
      'scheduler_default_filters':
        line   => 'scheduler_default_filters=PciPassthroughFilter',
        path   => '/etc/nova/nova.conf',
        after  => '^\s*\[DEFAULT\]';
      'scheduler_available_filters':
        line   => 'scheduler_available_filters=nova.scheduler.filters.pci_passthrough_filter.PciPassthroughFilter',
        path   => '/etc/nova/nova.conf',
        after  => '^\s*\[DEFAULT\]';
      'scheduler_available_filters2':
        line   => 'scheduler_available_filters=nova.scheduler.filters.all_filters',
        path   => '/etc/nova/nova.conf',
        after  => '^\s*\[DEFAULT\]';
    }
  }
}
