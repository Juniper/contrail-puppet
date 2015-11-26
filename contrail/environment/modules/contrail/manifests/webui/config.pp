class contrail::webui::config(
    $config_ip = $::contrail::params::config_ip_list[0],
    $collector_ip = $::contrail::params::collector_ip_list[0],
    $openstack_ip = $::contrail::params::openstack_ip_list[0],
    $database_ip_list =  $::contrail::params::database_ip_list,
    $is_storage_master = $::contrail::params::storage_enabled,
    $keystone_ip = $::contrail::params::keystone_ip,
    $internal_vip = $::contrail::params::internal_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $redis_password = $::contrail::params::redis_password,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $config_ip_to_use = $::contrail::params::config_ip_to_use,
    $collector_ip_to_use = $::contrail::params::collector_ip_to_use,
    $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
    $openstack_ip_to_use = $::contrail::params::openstack_ip_to_use
) {

    case $::operatingsystem {
        Ubuntu: {
            #file {'/etc/init/supervisor-webui.override':
                #ensure  => absent,
            #} ->
            # Below is temporary to work-around in Ubuntu as Service resource fails
            # as upstart is not correctly linked to /etc/init.d/service-name
            #file { '/etc/init.d/supervisor-webui':
                #ensure => link,
                #target => '/lib/init/upstart-job',
            #}
        }
        default: {
        }
    }
    # Print all the variables
    notify { "webui - config_ip = ${config_ip}":;}
    notify { "webui - config_ip_to_use = ${config_ip_to_use}":;}
    notify { "webui - collector_ip = ${collector_ip}":;}
    notify { "webui - collector_ip_to_use = ${collector_ip_to_use}":;}
    notify { "webui - openstack_ip = ${openstack_ip}":;}
    notify { "webui - openstack_ip_to_use = ${openstack_ip_to_use}":;}
    notify { "webui - database_ip_list = ${database_ip_list}":;}
    notify { "webui - is_storage_master = ${is_storage_master}":;}
    notify { "webui - keystone_ip = ${keystone_ip}":;}
    notify { "webui - keystone_ip_to_use = ${keystone_ip_to_use}":;}
    notify { "webui - internal_vip = ${internal_vip}":;}
    notify { "webui - contrail_internal_vip = ${contrail_internal_vip}":;}
    notify { "webui - contrail_internal_vip_to_use = ${contrail_internal_vip_to_use}":;}

    if ($is_storage_master) {
        $ensure_storage = 'present'
    } else {
        $ensure_storage = 'absent'
    }

    file { '/etc/contrail/config.global.js' :
        ensure  => present,
        content => template("${module_name}/config.global.js.erb"),
    }
    ->
    file { 'storage.config.global.js':
        ensure  => $ensure_storage,
        path    => '/usr/src/contrail/contrail-web-storage/webroot/common/config/storage.config.global.js',
        content => template("${module_name}/storage.config.global.js.erb"),
    }
}
