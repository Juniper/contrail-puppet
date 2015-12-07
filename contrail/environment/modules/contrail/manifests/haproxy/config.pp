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
    notify {"Haproxy - tor_ha_config => ${tor_ha_proxy_config}":;}
    # Debug - Print all variables
    notify { "Haproxy - config_ip_list = ${config_ip_list}":; }
    notify { "Haproxy - config_name_list = ${config_name_list}":;}
    notify { "Haproxy - openstack_ip_list = ${openstack_ip_list}":; }
    notify { "Haproxy - openstack_name_list = ${openstack_name_list}":;}
    notify { "Haproxy - collector_ip_list = ${collector_ip_list}":; }
    notify { "Haproxy - collector_name_list = ${collector_name_list}":;}
    notify { "Haproxy - internal_vip = ${internal_vip}":; }
    notify { "Haproxy - contrail_internal_vip = ${contrail_internal_vip}":;}
    notify { "Haproxy - host_ip = ${host_ip}":;}
    $manage_amqp = 'no'

    if ($internal_vip == undef or $internal_vip == '') {
        $ha_internal_vip = 'none'
    } else {
        $ha_internal_vip = $internal_vip
    }
    if ($contrail_internal_vip == undef or $contrail_internal_vip == '') {
        $ha_contrail_internal_vip = 'none'
    } else {
        $ha_contrail_internal_vip = $contrail_internal_vip
    }

    $openstack_ip_list_shell = inline_template('<%= @openstack_ip_list.map{ |name2| "#{name2}" }.join(",") %>')
    $config_ip_list_shell = inline_template('<%= @config_ip_list.map{ |name2| "#{name2}" }.join(",") %>')
    $collector_ip_list_shell = inline_template('<%= @collector_ip_list.map{ |name2| "#{name2}" }.join(",") %>')

    $openstack_name_list_shell = inline_template('<%= @openstack_name_list.map{ |name2| "#{name2}" }.join(",") %>')
    $config_name_list_shell = inline_template('<%= @config_name_list.map{ |name2| "#{name2}" }.join(",") %>')
    $collector_name_list_shell = inline_template('<%= @collector_name_list.map{ |name2| "#{name2}" }.join(",") %>')

    $contrail_exec_haproxy_gen = "python /opt/contrail/bin/generate_haproxy.py  && echo generate_ha_config >> /etc/contrail/contrail_openstack_exec.out"

    notify { "haproxy cmd  $contrail_exec_haproxy_gen":;}
    -> file { '/opt/contrail/bin/generate_haproxy.py' :
        ensure => present,
        mode   => '0755',
        group  => root,
        content => template("${module_name}/generate_haproxy.erb")
    }
    ->
    exec { 'generate_ha_config' :
        command   => $contrail_exec_haproxy_gen,
        provider  => shell,
        logoutput => $contrail_logoutput
    }
}