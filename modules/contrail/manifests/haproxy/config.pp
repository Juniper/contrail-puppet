class contrail::haproxy::config(
    $config_ip_list = $::contrail::params::config_ip_list,
    $config_name_list =  $::contrail::params::config_name_list,
    $openstack_ip_list = $::contrail::params::openstack_ip_list,
    $openstack_name_list =  $::contrail::params::openstack_name_list,
    $collector_ip_list = $::contrail::params::collector_ip_list,
    $collector_name_list =  $::contrail::params::collector_name_list,
    $contrail_internal_vip =  $::contrail::params::contrail_internal_vip,
    $internal_vip =  $::contrail::params::internal_vip,
    $host_ip = $::contrail::params::host_ip,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $tor_ha_proxy_config = $::contrail::params::tor_ha_config
) {

    $ha_internal_vip = pick($internal_vip, 'none')
    $ha_contrail_internal_vip = pick($contrail_internal_vip, 'none')
    $openstack_ip_list_shell   = join($openstack_ip_list, ",")
    $openstack_name_list_shell = join($openstack_name_list, ",")
    $config_ip_list_shell   = join($config_ip_list, ",")
    $config_name_list_shell = join($config_name_list, ",")
    $collector_ip_list_shell   = join($collector_ip_list, ",")
    $collector_name_list_shell = join($collector_name_list, ",")
    $contrail_exec_haproxy_gen = "python /opt/contrail/bin/generate_haproxy.py  && echo generate_ha_config >> /etc/contrail/contrail_openstack_exec.out"

    notify { "haproxy cmd  $contrail_exec_haproxy_gen":;} ->
    file { '/opt/contrail/bin/generate_haproxy.py' :
        ensure => present,
        mode   => '0755',
        group  => root,
        content => template("${module_name}/generate_haproxy.erb")
    } ->
    exec { 'generate_ha_config' :
        command   => $contrail_exec_haproxy_gen,
        provider  => shell,
        logoutput => $contrail_logoutput
    }
}
