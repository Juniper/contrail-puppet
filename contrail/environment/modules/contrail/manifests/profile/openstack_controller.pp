# == Class: contrail::profile::openstack
# The puppet module to set up a openstack controller
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
# [*enable_ceilometer*]
#     Flag to include or exclude ceilometer service as part of openstack module dynamically.
#     (optional) - Defaults to false.
#
class contrail::profile::openstack_controller (
    $enable_module = $::contrail::params::enable_openstack,
    $enable_ceilometer = $::contrail::params::enable_ceilometer
) {
    if ($enable_module) {
        contrail::lib::report_status { "openstack_started": state => "openstack_started" } ->
        class {'::openstack::profile::base' : } ->
        class {'::nova::quota' :
              quota_instances => 10000,
        } ->
        class {'::openstack::profile::firewall' : } ->
        class {'::contrail::profile::openstack::mysql' : } ->
        class {'::openstack::profile::keystone' : } ->
        class {'::openstack::profile::memcache' : } ->
        class {'::contrail::profile::openstack::glance::api' : } ->
        class {'::openstack::profile::cinder::api' : } ->
        class {'::openstack::profile::nova::api' : } ->
        class {'::contrail::profile::openstack::heat' : } ->
        class {'::openstack::profile::horizon' : } ->
        class {'::openstack::profile::auth_file' : } ->
        class {'::openstack::profile::provision' : } ->
        class {'::contrail::contrail_openstack' : } ->
        #Contrail expects neutron to run on config nodes only
        class {'::contrail::profile::openstack::neutron::server' : } ->

    package { 'contrail-openstack-dashboard':
      ensure  => latest,
    } ->

        # Though neutron runs on config, setup the db in openstack node
        exec { 'neutron-db-sync':
            command     => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head',
            path        => '/usr/bin',
            before      => Service['neutron-server'],
            require     => Neutron_config['database/connection'],
            refreshonly => true
        } ->
        contrail::lib::report_status { "openstack_completed": state => "openstack_completed" }

        Class['::neutron::db::mysql'] -> Exec['neutron-db-sync']
        Class['::openstack::profile::provision']->Service['glance-api']
        if ($enable_ceilometer) {
            include ::contrail::profile::openstack::ceilometer
        }
        notify { "contrail::profile::openstack_controller - enable_ceilometer = $enable_ceilometer":; }
    }

}
