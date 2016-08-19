# == class: contrail::profile::global_controller
#
# base glance config.
#
# === parameters:
#
#  [*package_ensure*]
#    (Optional) Ensure state for package. On Ubuntu this setting
#    is ignored since Ubuntu has separate API and registry packages.
#    Defaults to 'present'
#
class contrail::profile::global_controller(
  $package_ensure = 'present',
  $enable_module = $::contrail::params::enable_global_controller,
  $is_there_roles_to_delete = $::contrail::params::is_there_roles_to_delete,
  $host_roles = $::contrail::params::host_roles,
) {
  if ($enable_module and 'global_controller' in $host_roles and $is_there_roles_to_delete == false) {
      include ::contrail::profile::global_controller::params

      Class['::contrail::profile::global_controller::install'] ~>
      Class['::contrail::profile::global_controller::config'] ~>
      Class['::contrail::profile::global_controller::service']

      contain ::contrail::profile::global_controller::install
      contain ::contrail::profile::global_controller::config
      contain ::contrail::profile::global_controller::service
  }
}
