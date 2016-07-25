# these parameters need to be accessed from several locations and
# should be considered to be constant
include contrail::params

class contrail::profile::global_controller::params {
  $package_name = 'ukai'
}
