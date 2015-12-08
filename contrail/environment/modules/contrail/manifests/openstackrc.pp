class contrail::openstackrc(
  $keystone_admin_user = $::contrail::params::keystone_admin_user,
  $keystone_admin_password = $::contrail::params::keystone_admin_password,
  $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
  $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
) {
  # Create openstackrc file.
  file { '/etc/contrail/openstackrc' :
      ensure  => present,
      content => template("${module_name}/openstackrc.erb"),
  }
}
