class contrail::keystone (
    $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
    $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol,
    $keystone_auth_port = $::contrail::params::keystone_auth_port,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $keystone_insecure_flag = $::contrail::params::keystone_insecure_flag,
    $multi_tenancy = $::contrail::params::multi_tenancy,
    $host_roles = $::contrail::params::host_roles,
) {
  contrail_keystone_auth_config {
    'KEYSTONE/auth_host' : value => $keystone_ip_to_use;
    'KEYSTONE/auth_protocol' : value => $keystone_auth_protocol;
    'KEYSTONE/auth_port' : value => $keystone_auth_port;
    'KEYSTONE/admin_user' : value => $keystone_admin_user;
    'KEYSTONE/admin_password' : value => $keystone_admin_password;
    'KEYSTONE/admin_tenant_name' : value => $keystone_admin_tenant;
    'KEYSTONE/insecure' :  value => $keystone_insecure_flag;
  }
  if (($multi_tenancy == true) and ('config' in $host_roles)) {
    contrail_keystone_auth_config {
      'KEYSTONE/memcache_servers' : value => '127.0.0.1:11211'
    }
  }
}
