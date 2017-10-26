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
  $sync_db           = $::contrail::params::os_sync_db,
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
  $keystone_ip_to_use         = $::contrail::params::keystone_ip_to_use,
  $keystone_admin_password    = $::contrail::params::keystone_admin_password,
  $config_ip_to_use           = $::contrail::params::config_ip_to_use,
  $openstack_ip_to_use        = $::contrail::params::openstack_ip_to_use,
  $rabbit_use_ssl     = $::contrail::params::os_amqp_ssl,
  $kombu_ssl_ca_certs = $::contrail::params::kombu_ssl_ca_certs,
  $kombu_ssl_certfile = $::contrail::params::kombu_ssl_certfile,
  $kombu_ssl_keyfile  = $::contrail::params::kombu_ssl_keyfile,
  $vncproxy_port      = $::contrail::params::vncproxy_port,
  $vncproxy_host      = $::contrail::params::vncproxy_host,
  $vncproxy_url       = $::contrail::params::vncproxy_base_url,
  $nova_compute_rabbit_hosts = $::contrail::params::nova_compute_rabbit_hosts,
  $keystone_auth_protocol    = $::contrail::params::keystone_auth_protocol,
  $neutron_ip_to_use   = $::contrail::params::neutron_ip_to_use,
  $metadata_ssl_enable = $::contrail::params::metadata_ssl_enable,
  $hostname_lower      = $::contrail::params::hostname_lower
) {

  $auth_uri = "${keystone_auth_protocol}://${keystone_ip_to_use}:5000/"
  $identity_uri = "${keystone_auth_protocol}://${keystone_ip_to_use}:35357/"

  class {'::nova::db::mysql':
    password      => $service_password,
    allowed_hosts => $allowed_hosts,
  }


  $compute_ip_list = $::contrail::params::compute_ip_list
  $tmp_index = inline_template('<%= @compute_ip_list.index(@host_control_ip) %>')

  if ($tmp_index != nil and $tmp_index != undef and $tmp_index != "" ) {
    $contrail_is_compute = true
  } else {
    $contrail_is_compute = false
  }

  $memcache_ip_ports = suffix($openstack_ip_list, ":11211")

  if ($internal_vip != "" and $internal_vip != undef) {
    $osapi_compute_workers = '40'
    $database_idle_timeout = '180'
    $nova_api_port         = '9774'
    $metadata_port         = '9775'
    $mysql_ip_address      = $internal_vip
    $mysql_port_url        = ":33306/nova"
    $mysql_port_url_api    = ":33306/nova_api"
  } else {
    $osapi_compute_workers = $::processorcount
    $database_idle_timeout = '3600'
    $nova_api_port         = '8774'
    $metadata_port         = '8775'
    $mysql_ip_address      = $host_control_ip
    $mysql_port_url        = "/nova"
    $mysql_port_url_api    = "/nova_api"
  }

  $database_credentials = join([$service_password, "@", $mysql_ip_address],'')
  $keystone_db_conn = join(["mysql://nova:",$database_credentials,$mysql_port_url],'')

  if ($metadata_ssl_enable){
    file {["/etc/nova/ssl", "/etc/nova/ssl/certs", "/etc/nova/ssl/private"]:
      owner  => nova,
      group  => nova,
      ensure  => directory,
    }
    file { "/etc/nova/ssl/certs/nova.pem":
      owner  => nova,
      group  => nova,
      source => "puppet:///ssl_certs/${hostname_lower}.pem"
    }
    file { "/etc/nova/ssl/private/novakey.pem":
      owner  => nova,
      group  => nova,
      source => "puppet:///ssl_certs/${hostname_lower}-privkey.pem"
    }
    file { "/etc/nova/ssl/certs/ca.pem":
      owner  => nova,
      group  => nova,
      source => "puppet:///ssl_certs/ca-cert.pem"
    }
  }
  case $package_sku {
    /14\.0/: {
      $nova_api_db_conn = join(["mysql://nova_api:",$database_credentials, $mysql_port_url_api],'')
      class {'::nova::db::mysql_api':
        password      => $service_password,
        allowed_hosts => $allowed_hosts,
      }
      class { '::nova':
        database_connection => $keystone_db_conn,
        glance_api_servers  => "http://${openstack_ip_to_use}:9292",
        memcached_servers   => [$memcache_ip_ports],
        rabbit_hosts        => $openstack_rabbit_servers,
        rabbit_userid       => $rabbitmq_user,
        rabbit_password     => $rabbitmq_password,
        rabbit_retry_interval  => "1",
        rabbit_retry_backoff   => "2",
        rabbit_max_retries     => "0",
        verbose             => $openstack_verbose,
        debug               => $openstack_debug,
        use_syslog          => false,
        use_stderr          => false,
        notification_driver => "nova.openstack.common.notifier.rpc_notifier",
        api_database_connection => $nova_api_db_conn,
        database_idle_timeout   => $database_idle_timeout,
        database_min_pool_size  => "100",
        database_max_pool_size  => "350",
        database_max_overflow   => "700",
        database_retry_interval => "5",
        database_max_retries    => "-1",
        rabbit_use_ssl     => $rabbit_use_ssl,
        kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
        kombu_ssl_certfile => $kombu_ssl_certfile,
        kombu_ssl_keyfile  => $kombu_ssl_keyfile,
        enabled_ssl_apis   => ['metadata']
        use_ssl            => $metadata_ssl_enable,
        cert_file          => "/etc/nova/ssl/certs/nova.pem",
        key_file           => "/etc/nova/ssl/private/novakey.pem",
        ca_file            => "/etc/nova/ssl/certs/ca.pem",
      }

      class { '::nova::api':
        osapi_compute_listen_port            => $nova_api_port,
        metadata_listen_port                 => $metadata_port,
        admin_password                       => $nova_password,
        auth_uri                             => $auth_uri,
        enabled                              => 'true',
        sync_db                              => $sync_db,
        osapi_compute_workers                => $osapi_compute_workers,
      }

      class { '::nova::network::neutron':
        neutron_admin_password => $neutron_password,
        neutron_region_name    => $region_name,
        neutron_admin_auth_url => "http://${keystone_ip_to_use}:35357/",
        neutron_url            => "http://${neutron_ip_to_use}:9696",
        neutron_auth_type      => 'password',
        vif_plugging_is_fatal  => false,
        vif_plugging_timeout   => '0',
      }
      nova_config {
        'DEFAULT/scheduler_max_attempts':        value => '10';
        'DEFAULT/disable_process_locking':       value => 'True';
        'DEFAULT/rabbit_interval':               value => '15';
        'DEFAULT/pool_timeout':                  value => '120';
        'neutron/admin_auth_url'    :  value => "http://${keystone_ip_to_use}:35357/" ;
        'neutron/admin_tenant_name' : value => 'services';
        'neutron/admin_username'    : value => 'neutron';
        'neutron/admin_password'    : value => "${keystone_admin_password}";
        'neutron/url_timeout'       : value => "300";
        'compute/compute_driver'    : value => "libvirt.LibvirtDriver";
        'DEFAULT/rabbit_hosts'      : value => "${nova_compute_rabbit_hosts}";
        'vnc/novncproxy_base_url' : value => "${vncproxy_url}";
        'DEFAULT/nova_metadata_protocol': value => "https";
        'DEFAULT/nova_metadata_insecure': value => "True";
      }

      if ($neutron_shared_secret){
        nova_config {
          'neutron/metadata_proxy_shared_secret':
            value => $neutron_shared_secret;
        }
      }

    }

    /13\.0/: {
      $nova_api_db_conn = join(["mysql://nova_api:",$database_credentials, $mysql_port_url_api],'')
      class {'::nova::db::mysql_api':
        password      => $service_password,
        allowed_hosts => $allowed_hosts,
      }
      $enabled_apis = ['osapi_compute,metadata']
      class { '::nova':
        database_connection => $keystone_db_conn,
        glance_api_servers  => "http://${openstack_ip_to_use}:9292",
        memcached_servers   => [$memcache_ip_ports],
        rabbit_hosts        => $openstack_rabbit_servers,
        rabbit_userid       => $rabbitmq_user,
        rabbit_password     => $rabbitmq_password,
        verbose             => $openstack_verbose,
        debug               => $openstack_debug,
        notification_driver => "nova.openstack.common.notifier.rpc_notifier",
        api_database_connection => $nova_api_db_conn,
        database_idle_timeout   => $database_idle_timeout,
        database_min_pool_size  => "100",
        database_max_pool_size  => "350",
        database_max_overflow   => "700",
        database_retry_interval => "5",
        database_max_retries    => "-1",
        rabbit_use_ssl     => $rabbit_use_ssl,
        kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
        kombu_ssl_certfile => $kombu_ssl_certfile,
        kombu_ssl_keyfile  => $kombu_ssl_keyfile,
        enabled_ssl_apis   => ['metadata']
        use_ssl            => $metadata_ssl_enable,
        cert_file          => "/etc/nova/ssl/certs/nova.pem",
        key_file           => "/etc/nova/ssl/private/novakey.pem",
        ca_file            => "/etc/nova/ssl/certs/ca.pem",
      }

      class { '::nova::api':
        osapi_compute_listen_port            => $nova_api_port,
        metadata_listen_port                 => $metadata_port,
        admin_password                       => $nova_password,
        auth_uri                             => $auth_uri,
        identity_uri                         => $identity_uri,
        enabled                              => 'true',
        sync_db                              => $sync_db,
        osapi_compute_workers                => $osapi_compute_workers,
        enabled_apis                         => $enabled_apis
      }

      class { '::nova::network::neutron':
        neutron_admin_password => $neutron_password,
        neutron_region_name    => $region_name,
        neutron_admin_auth_url => "${keystone_auth_protocol}://${keystone_ip_to_use}:35357/",
        neutron_url            => "http://${neutron_ip_to_use}:9696",
        vif_plugging_is_fatal  => false,
        vif_plugging_timeout   => '0',
      }
      nova_config {
        'DEFAULT/scheduler_max_attempts':        value => '10';
        'DEFAULT/disable_process_locking':       value => 'True';
        'oslo_messaging_rabbit/rabbit_retry_interval':         value => '1';
        'oslo_messaging_rabbit/rabbit_retry_backoff':          value => '2';
        'oslo_messaging_rabbit/rabbit_max_retries':            value => '0';
        'DEFAULT/rabbit_interval':               value => '15';
        'DEFAULT/pool_timeout':                  value => '120';
        'database/db_max_retries':               value => '3';
        'database/db_retry_interval':            value => '1';
        'database/connection_debug':             value => '10';
        'neutron/admin_auth_url'    : value => "${keystone_auth_protocol}://${keystone_ip_to_use}:35357/" ;
        'neutron/admin_tenant_name' : value => 'services';
        'neutron/admin_username'    : value => 'neutron';
        'neutron/auth_type'         : value => 'password';
        'neutron/admin_password'    : value => "${keystone_admin_password}";
        'neutron/url_timeout'       : value => "300";
        'compute/compute_driver'    : value => "libvirt.LibvirtDriver";
        'DEFAULT/rabbit_hosts'      : value => "${nova_compute_rabbit_hosts}";
        'vnc/novncproxy_base_url' : value => "${vncproxy_url}";
        'keystone_authtoken/insecure' : value => "True";
      }

      if ($neutron_shared_secret){
        nova_config {
          'neutron/metadata_proxy_shared_secret':
            value => $neutron_shared_secret;
        }
      }

    }

    default: {
      $enabled_apis = ['ec2,osapi_compute,metadata']
      class { '::nova':
        database_connection => $keystone_db_conn,
        glance_api_servers  => "http://${openstack_ip_to_use}:9292",
        memcached_servers   => [$memcache_ip_ports],
        rabbit_hosts        => $openstack_rabbit_servers,
        rabbit_userid       => $rabbitmq_user,
        rabbit_password     => $rabbitmq_password,
        verbose             => $openstack_verbose,
        debug               => $openstack_debug,
        notification_driver => "nova.openstack.common.notifier.rpc_notifier",
        database_idle_timeout => $database_idle_timeout,
        rabbit_use_ssl     => $rabbit_use_ssl,
        kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
        kombu_ssl_certfile => $kombu_ssl_certfile,
        kombu_ssl_keyfile  => $kombu_ssl_keyfile,
        enabled_ssl_apis   => ['metadata']
        use_ssl            => $metadata_ssl_enable,
        cert_file          => "/etc/nova/ssl/certs/nova.pem",
        key_file           => "/etc/nova/ssl/private/novakey.pem",
        ca_file            => "/etc/nova/ssl/certs/ca.pem",
      }
      class { '::nova::api':
        admin_password                       => $nova_password,
        auth_host                            => $keystone_ip_to_use,
        auth_uri                             => $auth_uri,
        enabled                              => 'true',
        sync_db                              => $sync_db,
        osapi_compute_workers                => $osapi_compute_workers,
        enabled_apis                         => $enabled_apis
      }

      class { '::nova::network::neutron':
        neutron_admin_password => $neutron_password,
        neutron_region_name    => $region_name,
        neutron_admin_auth_url => "http://${keystone_ip_to_use}:35357/v2.0",
        neutron_url            => "http://${neutron_ip_to_use}:9696",
        vif_plugging_is_fatal  => false,
        vif_plugging_timeout   => '0',
      }

      nova_config {
        'DEFAULT/osapi_compute_listen_port':     value => $nova_api_port;
        'DEFAULT/metadata_listen_port':          value => $metadata_port;
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

      if ($neutron_shared_secret){
        nova_config {
          'neutron/metadata_proxy_shared_secret':
            value => $neutron_shared_secret;
        }
      }
    }
  }


  if ($enable_ceilometer) {
    $instance_usage_audit = 'True'
    $instance_usage_audit_period = 'hour'
  }

  class { '::nova::vncproxy':
    enabled => 'true',
    port    => $vncproxy_port,
  }

  class { [
    'nova::scheduler',
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
      vncproxy_host                 => $vncproxy_host,
      instance_usage_audit          => $instance_usage_audit,
      instance_usage_audit_period   => $instance_usage_audit_period
    }

    #TODO make sure we have vif package

    class { '::nova::compute::neutron':
      libvirt_vif_driver => "nova_contrail_vif.contrailvif.VRouterVIFDriver"
    }
  }

  if ($sriov_enable) {
    file_line {
      'scheduler_default_filters':
        line   => 'scheduler_default_filters=RetryFilter, AvailabilityZoneFilter, RamFilter, ComputeFilter, ComputeCapabilitiesFilter, ImagePropertiesFilter, PciPassthroughFilter',
        path   => '/etc/nova/nova.conf',
        after  => '^\s*\[DEFAULT\]';
      'scheduler_available_filters':
        line   => 'scheduler_available_filters=nova.scheduler.filters.all_filters',
        path   => '/etc/nova/nova.conf',
        after  => '^\s*\[DEFAULT\]';
    }
  }
}
