class contrail::collector::install {
    exec { 'Temporarily delete contrail-analytics to upgrade python-kafka' :
          command   => "dpkg -P contrail-analytics python-kafka-python",
          provider  => shell,
          logoutput => $contrail_logoutput,
    } ->
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
