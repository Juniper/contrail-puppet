class contrail::profile::global_controller::install () {
    package { $contrail::profile::global_controller::params::package_name :
        ensure => $package_ensure,
        name   => $::contrail::profile::global_controller::params::package_name,
    }
}
