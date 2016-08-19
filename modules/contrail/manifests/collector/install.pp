class contrail::collector::install(
    $upgrade_needed = $::contrail::params::upgrade_needed,
) {
    if ($upgrade_needed == 1) {
        exec { 'Temporarily delete contrail-analytics to upgrade python-kafka' :
            command   => "dpkg -P contrail-analytics contrail-openstack-analytics python-kafka-python",
            provider  => shell,
            logoutput => $contrail_logoutput,
        }
        Exec['Temporarily delete contrail-analytics to upgrade python-kafka'] -> Package['python-kafka']
    }
    package {'python-kafka':
        ensure => latest,
        notify => Service['supervisor-analytics']
    } ->
    package { ['contrail-analytics','contrail-openstack-analytics', 'contrail-docs'] :
        ensure => latest,
        configfiles => "replace",
        notify => Service['supervisor-analytics']
    }
}
