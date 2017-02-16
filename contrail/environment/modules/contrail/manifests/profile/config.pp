# == Class: contrail::profile::config
# The puppet module to set up a Contrail Config server
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
class contrail::profile::config (
  $enable_module  = $::contrail::params::enable_config,
  $is_there_roles_to_delete = $::contrail::params::is_there_roles_to_delete,
  $host_roles     = $::contrail::params::host_roles,
  $manage_neutron = $::contrail::params::manage_neutron,
  $ansible_provision = $::contrail::params::ansible_provision,
) {

  if ($enable_module and 'config' in $host_roles and $is_there_roles_to_delete == false) {
    contain ::contrail::config
    #contrail expects neutron server to run on configs
    if ($manage_neutron == true) {
      contain ::contrail::profile::neutron_server
      Class['::contrail::config']->Class['::contrail::profile::neutron_server']
    }
  } elsif ((!('config' in $host_roles)) and ($contrail_roles['config'] == true) and ($ansible_provision == false)) {
    notify { 'uninstalling config':; }
    contain ::contrail::uninstall_config
    Notify['uninstalling config']->Class['::contrail::uninstall_config']
  }
}
