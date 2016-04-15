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
  $is_there_roles_to_delete = $::contrail::params::is_there_roles_to_delete,
  $host_roles = $::contrail::params::host_roles,
  $package_sku = $::contrail::params::package_sku,
  $openstack_manage_amqp = $::contrail::params::openstack_manage_amqp
) {
    if ($enable_module and 'openstack' in $host_roles and $is_there_roles_to_delete == false) {
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
        #class {'::openstack::profile::horizon' : } ->
        class {'::openstack::profile::auth_file' : } ->
        class {'::openstack::profile::provision' : } ->
        class {'::contrail::contrail_openstack' : } ->
        package { 'openstack-dashboard': ensure => present } ->
        file {'/etc/openstack-dashboard/local_settings.py':
            ensure => present,
            mode   => '0755',
            group  => root,
            content => template("${module_name}/local_settings.py.erb")
        }
        Class['::openstack::profile::provision']->Service['glance-api']
        if ($enable_ceilometer) {
            contain ::contrail::profile::openstack::ceilometer
        }
        notify { "contrail::profile::openstack_controller - enable_ceilometer = ${enable_ceilometer}":; }

        if ($package_sku !~ /^*2015.1.*/) {
            package { 'contrail-openstack-dashboard':
                ensure  => latest,
            }
            Package['contrail-openstack-dashboard'] -> Exec['openstack-neutron-db-sync']
        }


        openstack::resources::database { 'neutron': }
        ->
        package { 'neutron-server': ensure => present }
        ->
        class {'::contrail::profile::neutron_db_sync':
            database_connection => $::openstack::resources::connectors::neutron
        }
        ->
        package { 'contrail-openstack':
            ensure    => latest,
        }
        ->
        notify { "contrail::profile::openstack_controller - neutron_db_connection = ${::openstack::resources::connectors::neutron}":; }
        if ($openstack_manage_amqp and ! defined(Class['::contrail::rabbitmq']) ) {
            contain ::contrail::rabbitmq
            Package['contrail-openstack'] -> Class['::contrail::rabbitmq'] -> Exec['exec_start_supervisor_openstack']
        }
        Package['contrail-openstack'] -> Exec['exec_start_supervisor_openstack']
        exec { 'exec_start_supervisor_openstack' :
            command   => 'service supervisor-openstack restart && echo start_supervisor_openstack >> /etc/contrail/contrail_openstack_exec.out',
            provider  => shell,
            require   => [ Package['contrail-openstack']  ],
            logoutput => $contrail_logoutput
        }
        ->
        contrail::lib::report_status { 'openstack_completed': state => 'openstack_completed' }

    } elsif ((!('openstack' in $host_roles)) and ($contrail_roles['openstack'] == true)) {

      notify { 'uninstalling openstack':; }
      contain ::contrail::uninstall_openstack
    }
}
