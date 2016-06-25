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
  $openstack_manage_amqp = $::contrail::params::openstack_manage_amqp,
  $neutron_ip_to_use = $::contrail::params::neutron_ip_to_use
) {
  $processor_count_str = "${::processorcount}"
  if ($enable_module and 'openstack' in $host_roles and $is_there_roles_to_delete == false) {
    contrail::lib::report_status { 'openstack_started': state => 'openstack_started' } ->
    package {'contrail-openstack' :
      ensure => latest,
      before => Class['::mysql::server']
    } ->
    class { 'memcached': 
        processorcount => $processor_count_str
    }->
    class {'::nova::quota' :
        quota_instances => 10000,
    } ->
    class {'::contrail::contrail_openstack' : } ->
    class {'::contrail::profile::openstack::mysql' : } ->
    Package['python-openstackclient'] ->
    class {'::contrail::profile::openstack::keystone' : } ->
    class {'::contrail::profile::openstack::glance' : } ->
    class {'::contrail::profile::openstack::cinder' : } ->
    class {'::contrail::profile::openstack::nova' : } ->
    class {'::contrail::profile::openstack::neutron' : } ->
    class {'::contrail::profile::openstack::heat' : } ->
    class {'::contrail::profile::openstack::provision' : } ->
    class {'::contrail::profile::openstack::auth_file' : } ->
    package { 'openstack-dashboard': ensure => present } ->
    file {'/etc/openstack-dashboard/local_settings.py':
      ensure => present,
      mode   => '0755',
      group  => root,
      content => template("${module_name}/local_settings.py.erb")
    }
    ->
    contrail::lib::report_status { 'openstack_completed':
      state => 'openstack_completed' ,
      require => [Class['keystone::endpoint'], Keystone_role['admin']]
    }

    contain ::contrail::profile::openstack::mysql
    contain ::contrail::profile::openstack::keystone
    contain ::contrail::profile::openstack::glance
    contain ::contrail::profile::openstack::cinder
    contain ::contrail::profile::openstack::nova
    contain ::contrail::profile::openstack::neutron
    contain ::contrail::profile::openstack::heat

    if ($::operatingsystem == 'Ubuntu') {
        service { 'supervisor-openstack': enable => true, ensure => running }
        Class['::contrail::profile::openstack::cinder'] -> Service['supervisor-openstack'] -> Class['::contrail::profile::openstack::nova']
    }
    if ($enable_ceilometer) {
      class {'::contrail::profile::openstack::ceilometer' : 
        before => Class['::contrail::profile::openstack::provision']
      }
      contain ::contrail::profile::openstack::ceilometer
    }

    contain ::contrail::profile::openstack::provision
    contain ::contrail::profile::openstack::auth_file
    contain ::contrail::contrail_openstack

    if ($openstack_manage_amqp and !  defined(Class['::contrail::rabbitmq']) ) {
      contain ::contrail::rabbitmq
      Package['contrail-openstack'] -> Class['::contrail::rabbitmq'] -> Class['::contrail::profile::openstack::cinder']
    }
  } elsif ((!('openstack' in $host_roles)) and ($contrail_roles['openstack'] == true)) {
    notify { 'uninstalling openstack':; }
    contain ::contrail::uninstall_openstack
  }
}
