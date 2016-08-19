class contrail::profile::global_controller::install () {
    contrail::lib::report_status { 'global_controller_started': state => 'global_controller_started' } ->
    package { $contrail::profile::global_controller::params::package_name :
        ensure => $package_ensure,
        name   => $::contrail::profile::global_controller::params::package_name,
    }
}
