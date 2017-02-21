# == Class: contrail::profile::compute
# The puppet module to set up a Contrail compute Node
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
# [*enable_ceilometer*]
#     Flag to include or exclude ceilometer service as part of openstack module dynamically.
#     (optional) - Defaults to false.
#
class contrail::profile::compute (
  $enable_module     = $::contrail::params::enable_compute,
  $enable_ceilometer = $::contrail::params::enable_ceilometer,
  $host_roles        = $::contrail::params::host_roles,
  $metering_secret   = $::contrail::params::os_metering_secret,
  $openstack_verbose = $::contrail::params::os_verbose,
  $openstack_debug   = $::contrail::params::os_debug,
  $keystone_version   = $::contrail::params::keystone_version,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
  $metering_secret    = $::contrail::params::os_metering_secret,
  $package_sku        = $::contrail::params::package_sku,
  $ceilometer_password        = $::contrail::params::os_ceilometer_password,
  $is_there_roles_to_delete   = $::contrail::params::is_there_roles_to_delete,
  $openstack_rabbit_servers   = $::contrail::params::openstack_rabbit_hosts,
) {
  if ($enable_module and "compute" in $host_roles and $is_there_roles_to_delete == false) {
    contain ::contrail::profile::nova::compute
    if ($enable_ceilometer and !("openstack" in $host_roles)) {
      #follow code is not needed if openstack role is there in host_roles
      #contain ::contrail::ceilometer::agent::auth
      $auth_url = "http://${keystone_ip_to_use}:5000/${keystone_version}"
      $identity_uri = "http://${keystone_ip_to_use}:35357/${keystone_version}"
      $auth_password = $ceilometer_password
      $auth_tenant_name = 'services'
      $auth_username = 'ceilometer'
      if ($keystone_version == "v3" ) {
        $domain_name = 'Default'
      } else {
        $domain_name = ''
      }
      if !defined(Class['::ceilometer']) {
        class { '::ceilometer':
          metering_secret => $metering_secret,
          debug           => $openstack_verbose,
          verbose         => $openstack_debug,
          rabbit_hosts    => $openstack_rabbit_servers,
          rpc_backend     => 'rabbit',
          rabbit_password => 'guest'
        }
      }
      class { '::ceilometer::agent::compute': }
      if ( $package_sku =~ /13\.0/) {
        class { '::ceilometer::agent::auth':
          auth_url         => $auth_url,
          auth_password    => $auth_password,
          auth_tenant_name => $auth_tenant_name,
          auth_user        => $auth_username,
          auth_project_domain_name => $domain_name,
          auth_user_domain_name => $domain_name
        }
      } else {
        class { '::ceilometer::agent::auth':
          auth_url         => $auth_url,
          auth_password    => $auth_password,
          auth_tenant_name => $auth_tenant_name,
          auth_user        => $auth_username,
        }
      }
      ceilometer_config {
        'service_credentials/os_auth_url' : value => $auth_url;
        'service_credentials/os_username' : value => $auth_username;
        'service_credentials/os_password' : value => $auth_password;
        'service_credentials/os_tenant_name' : value => $auth_tenant_name;
        'keystone_authtoken/auth_uri'     : value => $auth_url;
        'keystone_authtoken/identity_uri' : value => $identity_uri;
        'keystone_authtoken/admin_tenant_name' : value => $auth_tenant_name;
        'keystone_authtoken/admin_user'        : value => $auth_username;
        'keystone_authtoken/admin_password'    : value => $auth_password;
        'database/time_to_live'           : value => '7200';
        'publisher/telemetry_secret'      : value => $metering_secret;
        'DEFAULT/auth_strategy'           : value => 'keystone';
      } -> Service['ceilometer-agent-compute']
    }
  } elsif ((!("compute" in $host_roles)) and ($contrail_roles["compute"] == true)) {
    notify { "uninstalling compute":; }
    contain ::contrail::uninstall_compute
    Notify["uninstalling compute"]->Class['::contrail::uninstall_compute']
  }
}

