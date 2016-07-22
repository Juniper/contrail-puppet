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
  $package_ensure = 'present'
) {

  include ::contrail::profile::global_controller::params

  Class['::contrail::profile::global_controller::install'] ~>
  Class['::contrail::profile::global_controller::config'] ~>
  Class['::contrail::profile::global_controller::service']

  contain ::contrail::profile::global_controller::install
  contain ::contrail::profile::global_controller::config
  contain ::contrail::profile::global_controller::service
}
