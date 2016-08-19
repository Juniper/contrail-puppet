class contrail::webui::install (
    $is_storage_master = $::contrail::params::storage_enabled,
) {

    if ($is_storage_master) {
        $ensure_storage_package = 'latest'
    } else {
        $ensure_storage_package = 'absent'
    }

    package { 'contrail-openstack-webui' : ensure => latest, notify => Service['supervisor-webui']  }
    ->
    package { 'contrail-web-storage' : ensure => $ensure_storage_package, notify => Service['supervisor-webui'] }
}
