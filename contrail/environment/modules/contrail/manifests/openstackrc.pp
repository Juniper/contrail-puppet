class contrail::openstackrc(
  $keystone_admin_user = $::contrail::params::keystone_admin_user,
  $keystone_admin_password = $::contrail::params::keystone_admin_password,
  $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
  $keystone_auth_protocol = $::contrail::params::keystone_auth_protocol,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
  $keystone_region_name = $::contrail::params::keystone_region_name,
  $keystone_version     = $::contrail::params::keystone_version
) {
  # Create openstackrc file.
  file { '/etc/contrail/openstackrc' :
      ensure  => present,
      content => template("${module_name}/openstackrc.erb"),
  }
  if ($keystone_version == "v3") {
    file { '/etc/contrail/openstackrc_v3' :
      ensure  => present,
      content => template("${module_name}/openstackrc_v3.erb"),
    }
  }
}
