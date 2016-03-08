class contrail::collector::install {
    exec { 'Temporarily delete contrail-analytics to upgrade python-kafka' :
          command   => "dpkg -P contrail-analytics python-kafka-python",
          provider  => shell,
          logoutput => $contrail_logoutput,
          before => Package['python-kafka'],
    }
    package {'python-kafka':
        ensure => latest,
        before => Package['contrail-analytics']
    }
    package { ['contrail-analytics','contrail-openstack-analytics', 'contrail-docs'] :
        ensure => latest,
        configfiles => "replace",
    }
}
