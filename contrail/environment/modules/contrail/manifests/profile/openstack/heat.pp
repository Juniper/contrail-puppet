# == Class: contrail::profile::openstack::heat
# The puppet module to set up openstack::heat for contrail
#
#
class contrail::profile::openstack::heat () {
    include ::openstack::profile::heat::api
    $contrail_api_server = $::contrail::params::config_ip_to_use
    heat_config {
      'DEFAULT/plugin_dirs': value => "/usr/lib/heat/resources";
      'clients_contrail/user': value => "admin";
      'clients_contrail/password': value => "c0ntrail123";
      'clients_contrail/tenent': value => "admin";
      'clients_contrail/api_server': value => $contrail_api_server;
      'clients_contrail/api_base_url': value => "/";
    }
}
