class contrail::profile::global_controller::service() {
    service { $::contrail::profile::global_controller::params::package_name :
        ensure    => running,
        enable    => true,
    }->
    contrail::lib::report_status { 'global_controller_completed': state => 'global_controller_completed' }
}
