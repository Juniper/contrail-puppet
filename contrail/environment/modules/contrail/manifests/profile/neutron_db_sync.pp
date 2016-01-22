class contrail::profile::neutron_db_sync (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $database_connection = $::openstack::resources::connectors::neutron
) {
    exec { 'openstack-neutron-db-sync':
        command     => "neutron-db-manage --database-connection ${database_connection} upgrade head",
        path        => '/usr/bin',
        require     => Openstack::Resources::Database['neutron']
    }
}
