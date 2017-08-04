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
  $enable_module      = $::contrail::params::enable_openstack,
  $enable_ceilometer  = $::contrail::params::enable_ceilometer,
  $is_there_roles_to_delete = $::contrail::params::is_there_roles_to_delete,
  $host_roles         = $::contrail::params::host_roles,
  $package_sku        = $::contrail::params::package_sku,
  $openstack_manage_amqp = $::contrail::params::openstack_manage_amqp,
  $openstack_ip_list  = $::contrail::params::openstack_ip_list,
  $host_control_ip    = $::contrail::params::host_ip,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
  $keystone_version   = $::contrail::params::keystone_version,
  $rabbit_use_ssl     = $::contrail::params::os_amqp_ssl,
  $kombu_ssl_ca_certs = $::contrail::params::kombu_ssl_ca_certs,
  $kombu_ssl_certfile = $::contrail::params::kombu_ssl_certfile,
  $kombu_ssl_keyfile  = $::contrail::params::kombu_ssl_keyfile,
  $manage_neutron     = $::contrail::params::manage_neutron,
  $storage_enabled    = $::contrail::params::storage_enabled
) {

  $processor_count_str = "${::processorcount}"

  if ($enable_module and 'openstack' in $host_roles and $is_there_roles_to_delete == false) {
    contrail::lib::report_status { 'openstack_started': }
    -> Package[contrail-openstack]
    -> Package <|tag == 'openstack'|>

    package {'contrail-openstack' :
      ensure => latest,
      before => [ Class['::mysql::server']]
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
    class {'::contrail::profile::openstack::horizon' : } ->
    class {'::contrail::profile::openstack::auth_file' : } ->
    contrail::lib::report_status { 'openstack_completed':
      state => 'openstack_completed' ,
    }
    
    if ($storage_enabled ) {
      Contrail::Lib::Report_status['openstack_started'] ->
      class {'::contrail::profile::openstack::storage' : } ->
        Contrail::Lib::Report_status['openstack_completed']
    }

    if $keystone_version == "v3" {
      # setting new variable to reuse same json for keystone and horizon
      $horizon_v3_changes = "v3"
      Package['openstack-dashboard'] ->
      file { '/usr/share/openstack-dashboard/openstack_dashboard/conf/keystone_policy.json':
        ensure => present,
        mode   => '0755',
        group  => root,
        content => template("${module_name}/policy.v3cloudsample.json")
      } ->
      Contrail::Lib::Report_status['openstack_completed']
    }
    contain ::contrail::profile::openstack::mysql
    contain ::contrail::profile::openstack::keystone
    contain ::contrail::profile::openstack::glance
    contain ::contrail::profile::openstack::cinder
    contain ::contrail::profile::openstack::nova
    contain ::contrail::profile::openstack::neutron
    contain ::contrail::profile::openstack::heat
    contain ::contrail::profile::openstack::horizon

    Package ['contrail-openstack']
    -> contrail::lib::rabbitmq_ssl{'openstack_rabbitmq':
         rabbit_use_ssl => $rabbit_use_ssl }
    -> Contrail::Lib::Report_status['openstack_completed']

    if ($::operatingsystem == 'Ubuntu' and $::lsbdistrelease != '16.04') {
      service { 'supervisor-openstack':
        enable => true,
        ensure => running
      }

      Class['::contrail::profile::openstack::cinder']
      -> Service['supervisor-openstack']
      -> Class['::contrail::profile::openstack::nova']
    }

    if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
      class {'::contrail::rabbitmq' :
        require => Class['::contrail::profile::openstack::mysql'],
        before => Class['::contrail::profile::openstack::keystone']
      }
      contain ::contrail::rabbitmq
      Package['openstack-dashboard'] ->
      service { 'httpd':
        ensure  => running,
        enable  => true,
      }
    }

    if ($enable_ceilometer) {
      Contrail::Lib::Report_status['openstack_started'] ->

      Package ['contrail-openstack'] ->
      Package['mongodb_server']

      Class['::contrail::profile::mongodb'] ->
      Class['::contrail::profile::openstack::ceilometer']

      Contrail::Lib::Report_status['openstack_started'] ->
      Class['::Mongodb::Server']
      class {'::contrail::profile::openstack::ceilometer' : 
        before => Contrail::Lib::Report_status['openstack_completed']
      }
      contain ::contrail::profile::mongodb
      contain ::contrail::profile::openstack::ceilometer
    }

    contain ::contrail::profile::openstack::auth_file
    if ($host_control_ip == $openstack_ip_list[0]) {
      class { '::contrail::profile::openstack::provision':}

      Class ['::contrail::profile::openstack::heat'] ->
      Class ['::contrail::profile::openstack::auth_file'] ->
      Class ['::contrail::profile::openstack::provision']

      Class['keystone::endpoint'] -> Contrail::Lib::Report_status['openstack_completed']
      Keystone_role['admin'] -> Contrail::Lib::Report_status['openstack_completed']

      Keystone_endpoint <||>  -> Contrail::Lib::Report_status['openstack_completed']
      Keystone_user <||>  -> Contrail::Lib::Report_status['openstack_completed']
      Mysql_grant <||>  -> Contrail::Lib::Report_status['openstack_completed']

      contain ::contrail::profile::openstack::provision
    }

    contain ::contrail::contrail_openstack

    if ($openstack_manage_amqp and !defined(Class['::contrail::rabbitmq']) ) {
      contain ::contrail::rabbitmq
      Package['contrail-openstack'] -> Class['::contrail::rabbitmq'] -> Class['::contrail::profile::openstack::cinder']
    }


  } elsif ((!('openstack' in $host_roles)) and ($contrail_roles['openstack'] == true)) {
    contain ::contrail::uninstall_openstack
  }
}
