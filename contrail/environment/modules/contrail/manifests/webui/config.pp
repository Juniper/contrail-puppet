class contrail::webui::config(
    $database_ip_list =  $::contrail::params::database_ip_list,
    $config_ip_list =  $::contrail::params::config_ip_list,
    $is_storage_master = $::contrail::params::storage_enabled,
    $redis_password = $::contrail::params::redis_password,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $config_ip_to_use = $::contrail::params::config_ip_to_use,
    $collector_ip_to_use = $::contrail::params::collector_ip_to_use,
    $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
    $openstack_ip_to_use = $::contrail::params::openstack_ip_to_use,
    $webui_key_file_path = $::contrail::params::webui_key_file_path,
    $webui_cert_file_path = $::contrail::params::webui_cert_file_path,
) {

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
