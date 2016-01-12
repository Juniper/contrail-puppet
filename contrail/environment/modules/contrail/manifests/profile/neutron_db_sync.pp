class contrail::profile::neutron_db_sync (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $neutron_db_connection
) {
    exec { 'neutron-db-sync':
            command     => "neutron-db-manage --database-connection ${neutron_db_connection} upgrade head",
            path        => '/usr/bin'
    }
    ->
    notify { "executed reboot server" :; }
}
