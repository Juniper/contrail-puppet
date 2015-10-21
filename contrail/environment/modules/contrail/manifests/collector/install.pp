class contrail::collector::install {
    package { ['contrail-openstack-analytics', 'contrail-docs'] :
        ensure => latest,
    }
}
