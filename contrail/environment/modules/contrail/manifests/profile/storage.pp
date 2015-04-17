class contrail::profile::storage (
    $enable_storage_compute = $::contrail::params::enable_storage_compute,
    $enable_storage_master = $::contrail::params::enable_storage_master
)
{
    if ($enable_storage_compute) or ($enable_storage_master) {
        contain ::contrail::storage
    }
}
