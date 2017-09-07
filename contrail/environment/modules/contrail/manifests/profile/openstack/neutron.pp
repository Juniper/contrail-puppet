class contrail::profile::openstack::neutron(
  $host_control_ip   = $::contrail::params::host_ip,
  $allowed_hosts     = $::contrail::params::os_mysql_allowed_hosts,
  $config_ip         = $::contrail::params::config_ip_to_use,
  $multi_tenancy     = $::contrail::params::multi_tenancy,
  $collector_ip      = $::contrail::params::collector_ip_to_use,
  $keystone_admin_user      = $::contrail::params::keystone_admin_user,
  $keystone_admin_password  = $::contrail::params::keystone_admin_password,
  $keystone_admin_tenant    = $::contrail::params::keystone_admin_tenant,
  $contrail_plugin_location = $::contrail::params::contrail_plugin_location,
  $openstack_verbose = $::contrail::params::os_verbose,
  $openstack_debug   = $::contrail::params::os_debug,
  $region_name       = $::contrail::params::os_region,
  $nova_password     = $::contrail::params::os_nova_password,
  $rabbitmq_user     = $::contrail::params::os_rabbitmq_user,
  $rabbitmq_password = $::contrail::params::os_rabbitmq_password,
  $internal_vip      = $::contrail::params::internal_vip,
  $neutron_password  = $::contrail::params::os_neutron_password,
  $service_password  = $::contrail::params::os_mysql_service_password,
  $neutron_pkg_name  = $::contrail::params::neutron_pkg_name,
  $controller        = $::contrail::params::keystone_ip_to_use,
  $contrail_host_roles     = $::contrail::params::host_roles,
  $contrail_rabbit_servers = $::contrail::params::contrail_rabbit_hosts,
  $rabbit_use_ssl          = $::contrail::params::rabbit_ssl_support,
  $kombu_ssl_ca_certs      = $::contrail::params::kombu_ssl_ca_certs,
  $kombu_ssl_certfile      = $::contrail::params::kombu_ssl_certfile,
  $kombu_ssl_keyfile       = $::contrail::params::kombu_ssl_keyfile,
  $keystone_auth_protocol  = $::contrail::params::keystone_auth_protocol,
  $keystone_admin_token    = $::contrail::params::os_keystone_admin_token,
  $controller_mgmt_address = $::contrail::params::os_controller_mgmt_address,
  $package_sku             = $::contrail::params::package_sku,
  $keystone_ip_to_use      = $::contrail::params::keystone_ip_to_use,
  $neutron_mysql_ip        = $::contrail::params::neutron_mysql_to_use,
  $manage_neutron          = $::contrail::params::manage_neutron,
  $neutron_shared_secret   = $::contrail::params::os_neutron_shared_secret,
) {

  $database_credentials = join([$service_password, "@", $host_control_ip],'')
  $keystone_db_conn = join(["mysql://neutron:",$database_credentials,"/neutron"],'')

  if ($keystone_auth_protocol == "https") {
    $insecure = true
  } else {
    $insecure = false
  }

  if ($manage_neutron == false) {
    package { [ 'neutron-plugin-contrail', 'python-neutron-lbaas' ] :
      ensure => present
    }
  } else {
    package { $neutron_pkg_name :
      ensure => present
    }
  }
  class {'::neutron::db::mysql':
    password      => $service_password,
    allowed_hosts => $allowed_hosts,
  } ->

  class {'::contrail::profile::neutron_db_sync':
    database_connection => $keystone_db_conn
  }
  if ($manage_neutron == false) {
    if ($internal_vip != "" and $internal_vip != undef) {
      $neutron_port = "9697"
    } else {
      $neutron_port = "9696"
    }

    # Neutron needs to authenticate with keystone but doesn't need keystone installed
    # keystone_authtoken params
    $keystone_identity_uri = "${keystone_auth_protocol}://${keystone_ip_to_use}:35357/"
    $keystone_auth_uri = "${keystone_auth_protocol}://${keystone_ip_to_use}:5000"

    # sku pattern for centos is 12.0.1-1.el7.noarch. while
    # sku pattern for ubuntu is 2:12.0.1-0ubuntu1~cloud0.1contrail
    if ( $package_sku =~ /12\.0./) {
      $neutron_extensions = ":${::python_dist}/neutron_lbaas/extensions"
      $set_neutron_auth_pass = true
    } elsif ( $package_sku =~ /13\.0./) {
      $neutron_extensions = ":${::python_dist}/neutron_lbaas/extensions"
      $set_neutron_auth_pass = false
    } elsif ( $package_sku =~ /14\.0./) {
      $neutron_extensions = ":${::python_dist}/neutron_lbaas/extensions"
      $set_neutron_auth_pass = false
    } else {
      $neutron_extensions = ""
      $set_neutron_auth_pass = true
    }

    class { '::neutron':
      rabbit_hosts          => $contrail_rabbit_servers,
      rabbit_use_ssl        => $rabbit_use_ssl,
      kombu_ssl_ca_certs    => $kombu_ssl_ca_certs,
      kombu_ssl_certfile    => $kombu_ssl_certfile,
      kombu_ssl_keyfile     => $kombu_ssl_keyfile,
      bind_port             => $neutron_port,
      auth_strategy         => 'keystone',
      core_plugin           => 'neutron_plugin_contrail.plugins.opencontrail.contrail_plugin.NeutronPluginContrailCoreV2',
      allow_overlapping_ips => true,
      rabbit_user           => $rabbitmq_user,
      rabbit_password       => $rabbitmq_password,
      verbose               => $openstack_verbose,
      debug                 => $openstack_debug,
      api_extensions_path   => "extensions:${::python_dist}/neutron_plugin_contrail/extensions${neutron_extensions}",
      service_plugins       => ['neutron_plugin_contrail.plugins.opencontrail.loadbalancer.v2.plugin.LoadBalancerPluginV2'],
    }

    if ($neutron_shared_secret != "") {
      if ($set_neutron_auth_pass == true){
          class { '::neutron::agents::metadata':
              auth_password => $neutron_password,
              shared_secret       => $neutron_shared_secret,
          }
      } else {
          class { '::neutron::agents::metadata':
              shared_secret       => $neutron_shared_secret,
          }
      }
    }

    case $package_sku {
      /14\.0/: {
        class {'::neutron::keystone::authtoken':
          password => $neutron_password,
          auth_url => $keystone_identity_uri,
          auth_uri => $keystone_auth_uri,
        }
        class { '::neutron::server':
          database_connection => $keystone_db_conn,
          service_providers   => ['LOADBALANCER:Opencontrail:neutron_plugin_contrail.plugins.opencontrail.loadbalancer.driver.OpencontrailLoadbalancerDriver:default']
        }
        neutron_config {
          'keystone_authtoken/auth_host'    : value => "$keystone_ip_to_use";
          'keystone_authtoken/auth_port'    : value => "35357";
          'keystone_authtoken/auth_protocol': value => "${keystone_auth_protocol}";
          'keystone_authtoken/admin_user'   : value => "$keystone_admin_user";
          'keystone_authtoken/admin_password'   : value => "$keystone_admin_password";
          'keystone_authtoken/admin_tenant_name': value => "$keystone_admin_tenant";
        }
        contrail_plugin_ini {
          'APISERVER/api_server_ip'   : value => "$config_ip";
          'APISERVER/api_server_port' : value => '8082';
          'APISERVER/multi_tenancy'   : value => "$multi_tenancy";
          'APISERVER/contrail_extensions': value => 'ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam,policy:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_policy.NeutronPluginContrailPolicy,route-table:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_vpc.NeutronPluginContrailVpc,contrail:None,service-interface:None,vf-binding:None';
          'KEYSTONE/auth_url'         : value => "$keystone_auth_uri";
          'KEYSTONE/admin_user'       : value => "$keystone_admin_user";
          'KEYSTONE/admin_password'   : value => "$keystone_admin_password";
          'KEYSTONE/auth_user'        : value => "$keystone_admin_user";
          'KEYSTONE/admin_tenant_name': value => "$keystone_admin_tenant";
        } ->
        #NOTE: commented out for now, this will replace opencontrail_plugin_ini
        #class ::neutron::plugins::opencontrail {
            #api_server_ip               => "$config_ip",
            #$api_server_port            => "8082",
            #$multi_tenancy              =>"$multi_tenancy",
            #$contrail_extensions        => ["ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam",
                                            #"route-table:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_vpc.NeutronPluginContrailVpc",
                                            #"policy:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_policy.NeutronPluginContrailPolicy",
                                            #"contrail:None"]
            #$keystone_auth_url          => "$keystone_auth_uri",
            #$keystone_admin_user        =>"$keystone_admin_user",
            #$keystone_admin_tenant_name =>"$keystone_admin_tenant",
            #$keystone_admin_password    =>"$keystone_admin_password",
            #$keystone_admin_token       =>
        #}
        # contrail plugin for opencontrail
        opencontrail_plugin_ini {
          'APISERVER/api_server_ip'   : value => "$config_ip";
          'APISERVER/api_server_port' : value => '8082';
          'APISERVER/multi_tenancy'   : value => "$multi_tenancy";
          'APISERVER/contrail_extensions': value => 'ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam,policy:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_policy.NeutronPluginContrailPolicy,route-table:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_vpc.NeutronPluginContrailVpc,contrail:None';
          'KEYSTONE/auth_url'         : value => "$keystone_auth_uri";
          'KEYSTONE/admin_user'       : value => "$keystone_admin_user";
          'KEYSTONE/admin_password'   : value => "$keystone_admin_password";
          'KEYSTONE/auth_user'        : value => "$keystone_admin_user";
          'KEYSTONE/admin_tenant_name': value => "$keystone_admin_tenant";
          'COLLECTOR/analytics_api_ip': value => "$collector_ip";
          'COLLECTOR/analytics_api_port': value => "8081";
        } ->
        contrail::lib::augeas_conf_set { 'NEUTRON_PLUGIN_CONFIG':
          config_file => '/etc/default/neutron-server',
          settings_hash => { 'NEUTRON_PLUGIN_CONFIG' => $contrail_plugin_location, },
          lens_to_use => 'properties.lns',
        }
      }
      /13\.0/: {
        class { '::neutron::server':
          auth_password       => $neutron_password,
          auth_uri            => $keystone_auth_uri,
          identity_uri        => $keystone_identity_uri,
          database_connection => $keystone_db_conn,
          service_providers   => ['LOADBALANCER:Opencontrail:neutron_plugin_contrail.plugins.opencontrail.loadbalancer.driver.OpencontrailLoadbalancerDriver:default']
        }
        neutron_config {
          'keystone_authtoken/auth_host'    : value => "$keystone_ip_to_use";
          'keystone_authtoken/auth_port'    : value => "35357";
          'keystone_authtoken/auth_protocol': value => "${keystone_auth_protocol}";
          'keystone_authtoken/insecure'     : value => "$insecure";
        }
        contrail_plugin_ini {
          'APISERVER/api_server_ip'   : value => "$config_ip";
          'APISERVER/api_server_port' : value => '8082';
          'APISERVER/multi_tenancy'   : value => "$multi_tenancy";
          'APISERVER/contrail_extensions': value => 'ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam,policy:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_policy.NeutronPluginContrailPolicy,route-table:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_vpc.NeutronPluginContrailVpc,contrail:None,service-interface:None,vf-binding:None';
          'KEYSTONE/auth_url'         : value => "$keystone_auth_uri";
          'KEYSTONE/admin_user'       : value => "$keystone_admin_user";
          'KEYSTONE/admin_password'   : value => "$keystone_admin_password";
          'KEYSTONE/auth_user'        : value => "$keystone_admin_user";
          'KEYSTONE/admin_tenant_name': value => "$keystone_admin_tenant";
        } ->
        # contrail plugin for opencontrail
        opencontrail_plugin_ini {
          'APISERVER/api_server_ip'   : value => "$config_ip";
          'APISERVER/api_server_port' : value => '8082';
          'APISERVER/multi_tenancy'   : value => "$multi_tenancy";
          'APISERVER/contrail_extensions': value => 'ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam,policy:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_policy.NeutronPluginContrailPolicy,route-table:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_vpc.NeutronPluginContrailVpc,contrail:None';
          'KEYSTONE/auth_url'         : value => "$keystone_auth_uri";
          'KEYSTONE/admin_user'       : value => "$keystone_admin_user";
          'KEYSTONE/admin_password'   : value => "$keystone_admin_password";
          'KEYSTONE/auth_user'        : value => "$keystone_admin_user";
          'KEYSTONE/admin_tenant_name': value => "$keystone_admin_tenant";
          'COLLECTOR/analytics_api_ip': value => "$collector_ip";
          'COLLECTOR/analytics_api_port': value => "8081";
        } ->
        contrail::lib::augeas_conf_set { 'NEUTRON_PLUGIN_CONFIG':
          config_file => '/etc/default/neutron-server',
          settings_hash => { 'NEUTRON_PLUGIN_CONFIG' => $contrail_plugin_location, },
          lens_to_use => 'properties.lns',
        }
      }

      default: {
        class { '::neutron::server':
          auth_password       => $neutron_password,
          auth_uri            => $keystone_auth_uri,
          #identity_uri        => $keystone_identity_uri,
          database_connection => $keystone_db_conn,
          auth_host           =>"$keystone_ip_to_use",
          auth_protocol       => "http",
          auth_port           => "35357"
        }

        neutron_config {
          #'keystone_authtoken/auth_host'    : value => "$keystone_ip_to_use";
          #'keystone_authtoken/auth_port'    : value => "35357";
          #'keystone_authtoken/auth_protocol': value => "http";
          'DEFAULT/rpc_response_timeout'    : value => '60';
          'service_providers/service_provider': value => 'LOADBALANCER:Opencontrail:neutron_plugin_contrail.plugins.opencontrail.loadbalancer.driver.OpencontrailLoadbalancerDriver:default';
        }
        contrail_plugin_ini {
          'APISERVER/api_server_ip'   : value => "$config_ip";
          'APISERVER/api_server_port' : value => '8082';
          'APISERVER/multi_tenancy'   : value => "$multi_tenancy";
          'APISERVER/contrail_extensions': value => 'ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam,policy:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_policy.NeutronPluginContrailPolicy,route-table:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_vpc.NeutronPluginContrailVpc,contrail:None,service-interface:None,vf-binding:None';
          'KEYSTONE/auth_url'         : value => "$keystone_auth_uri";
          'KEYSTONE/admin_user'       : value => "$keystone_admin_user";
          'KEYSTONE/admin_password'   : value => "$keystone_admin_password";
          'KEYSTONE/auth_user'        : value => "$keystone_admin_user";
          'KEYSTONE/admin_tenant_name': value => "$keystone_admin_tenant";
        } ->
        # contrail plugin for opencontrail
        opencontrail_plugin_ini {
          'APISERVER/api_server_ip'   : value => "$config_ip";
          'APISERVER/api_server_port' : value => '8082';
          'APISERVER/multi_tenancy'   : value => "$multi_tenancy";
          'APISERVER/contrail_extensions': value => 'ipam:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_ipam.NeutronPluginContrailIpam,policy:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_policy.NeutronPluginContrailPolicy,route-table:neutron_plugin_contrail.plugins.opencontrail.contrail_plugin_vpc.NeutronPluginContrailVpc,contrail:None';
          'KEYSTONE/auth_url'         : value => "$keystone_auth_uri";
          'KEYSTONE/admin_user'       : value => "$keystone_admin_user";
          'KEYSTONE/admin_password'   : value => "$keystone_admin_password";
          'KEYSTONE/auth_user'        : value => "$keystone_admin_user";
          'KEYSTONE/admin_tenant_name': value => "$keystone_admin_tenant";
          'COLLECTOR/analytics_api_ip': value => "$collector_ip";
          'COLLECTOR/analytics_api_port': value => "8081";
        } ->
        contrail::lib::augeas_conf_set { 'NEUTRON_PLUGIN_CONFIG':
          config_file => '/etc/default/neutron-server',
          settings_hash => { 'NEUTRON_PLUGIN_CONFIG' => $contrail_plugin_location, },
          lens_to_use => 'properties.lns',
        }
      }
    }

    class { '::neutron::server::notifications':
      nova_url            => "http://${controller_mgmt_address}:8774/v2/",
      nova_admin_auth_url => "${keystone_auth_protocol}://${keystone_ip_to_use}:35357/v2.0/",
      nova_admin_password => $nova_password,
      nova_region_name    => $region_name,
      nova_admin_tenant_id => 'services'
    }

    # Contrail specific neutron config
    $neutron_contrail_params = {
      'quotas/quota_driver'  => {value => 'neutron_plugin_contrail.plugins.opencontrail.quota.driver.QuotaDriver'},
      'quotas/quota_network' => {value => '-1'},
      'quotas/quota_subnet'  => {value => '-1'},
      'quotas/quota_port'    => {value => '-1'},
      'DEFAULT/log_format'   => {value => '%(asctime)s.%(msecs)d %(levelname)8s [%(name)s] %(message)s'},
    }
    create_resources(neutron_config, $neutron_contrail_params, {} )

    # Openstack HA specific config
    if (($internal_vip != '')) {
      $neutron_ha_params = {
        'DEFAULT/rabbit_retry_interval' => { value => '1'},
        'DEFAULT/rabbit_retry_backoff' => {value => '2'},
        'DEFAULT/rabbit_max_retries' => { value => '0'},
        'DEFAULT/rpc_cast_timeout' => {value => '30'},
        'DEFAULT/rpc_conn_pool_size' => {value => '40'},
        'DEFAULT/rpc_thread_pool_size' => {value => '70'}
      }
      create_resources(neutron_config, $neutron_ha_params, {} )
    }
  }
}
