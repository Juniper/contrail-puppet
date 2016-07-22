class contrail::profile::global_controller::service() {
    service { $::contrail::profile::global_controller::params::package_name :
        ensure    => running,
        enable    => true,
    }
}
