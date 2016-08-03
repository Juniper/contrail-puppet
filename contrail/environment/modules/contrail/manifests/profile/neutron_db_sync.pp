class contrail::profile::neutron_db_sync (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $database_connection = $::openstack::resources::connectors::neutron
) {
    if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
        $cmd="/usr/bin/neutron-db-manage --database-connection ${database_connection} upgrade head"
    }
    if ($::operatingsystem == 'Ubuntu') {
        $cmd="neutron-db-manage --database-connection ${database_connection} upgrade head"
    }

    exec { 'openstack-neutron-db-sync':
        command     => "neutron-db-manage --database-connection ${database_connection} upgrade head",
        path        => '/usr/bin',
    }
}
