class contrail::compute::service(
  $nova_compute_status = $::contrail::compute::config::nova_compute_status
) {
    service { 'nova-compute' :
        enable => $nova_compute_status,
        ensure => $nova_compute_status,
    }
}
