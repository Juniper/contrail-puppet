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
  $enable_ceilometer = $::contrail::params::enable_ceilometer,
  $host_roles = $::contrail::params::host_roles
) {
    if ($enable_module and 'openstack' in $host_roles) {
        contrail::lib::report_status { 'openstack_started': state => 'openstack_started' } ->
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

        openstack::resources::database { 'neutron': } ->
        package { 'neutron-server': ensure => present }
        #package { 'openstack-dashboard':
          #ensure  => latest,
        #} ->

        # Though neutron runs on config, setup the db in openstack node
        $neutron_db_connection = $::openstack::resources::connectors::neutron
        notify { "contrail::profile::openstack_controller - neutron_db_connection = ${neutron_db_connection}":; }
        exec { 'neutron-db-sync':
            command     => "neutron-db-manage --database-connection ${neutron_db_connection} upgrade head",
            path        => '/usr/bin'
        } ->
        contrail::lib::report_status { 'openstack_completed': state => 'openstack_completed' }

        Class['::openstack::profile::provision']->Service['glance-api']
        if ($enable_ceilometer) {
            include ::contrail::profile::openstack::ceilometer
        }
        notify { "contrail::profile::openstack_controller - enable_ceilometer = ${enable_ceilometer}":; }

    } elsif ((!('openstack' in $host_roles)) and ($contrail_roles['openstack'] == true)) {

      notify { 'uninstalling openstack':; }
      contain ::contrail::uninstall_openstack
    }
}
