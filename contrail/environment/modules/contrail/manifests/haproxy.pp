# == Class: contrail::haproxy
#
# This class is used to configure haproxy service on config nodes.
#
# === Parameters:
#
# [*config_ip_list*]
#     List of control interface IP addresses of all the servers running config role.
#
# [*config_name_list*]
#     List of host names of all the servers running config role.
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
# The puppet module to set up a haproxy server
class contrail::haproxy (
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
) {
    require ::contrail::params


    # Debug - Print all variables
    notify { "Haproxy - config_ip_list = $config_ip_list":; }
    notify { "Haproxy - config_name_list = $config_name_list":;}
    notify { "Haproxy - openstack_ip_list = $openstack_ip_list":; }
    notify { "Haproxy - openstack_name_list = $openstack_name_list":;}
    notify { "Haproxy - collector_ip_list = $collector_ip_list":; }
    notify { "Haproxy - collector_name_list = $collector_name_list":;}
    notify { "Haproxy - internal_vip = $intenal_vip":; }
    notify { "Haproxy - contrail_internal_vip = $contrail_internal_vip":;}
    notify { "Haproxy - host_ip = $host_ip":;}
    $manage_amqp = "no"

    if ($internal_vip == undef or $internal_vip == "") {
        $ha_internal_vip = "none"
    } else {
        $ha_internal_vip = $internal_vip
    }
    if ($contrail_internal_vip == undef or $contrail_internal_vip == "") {
        $ha_contrail_internal_vip = "none"
    } else {
        $ha_contrail_internal_vip = $contrail_internal_vip
    }

    $openstack_ip_list_shell = inline_template('<%= @openstack_ip_list.map{ |name2| "#{name2}" }.join(",") %>')
    $config_ip_list_shell = inline_template('<%= @config_ip_list.map{ |name2| "#{name2}" }.join(",") %>')
    $collector_ip_list_shell = inline_template('<%= @collector_ip_list.map{ |name2| "#{name2}" }.join(",") %>')

    $openstack_name_list_shell = inline_template('<%= @openstack_name_list.map{ |name2| "#{name2}" }.join(",") %>')
    $config_name_list_shell = inline_template('<%= @config_name_list.map{ |name2| "#{name2}" }.join(",") %>')
    $collector_name_list_shell = inline_template('<%= @collector_name_list.map{ |name2| "#{name2}" }.join(",") %>')

    $contrail_exec_haproxy_gen = "python /opt/contrail/bin/generate_haproxy.py $host_ip $ha_internal_vip $ha_contrail_internal_vip $config_name_list_shell $config_ip_list_shell $openstack_name_list_shell $openstack_ip_list_shell $collector_name_list_shell $collector_ip_list_shell && service haproxy restart && echo generate_ha_config >> /etc/contrail/contrail_openstack_exec.out"


    package { 'haproxy' : ensure => present,}
    ->
    file { "/etc/haproxy/haproxy.cfg" : 
        ensure  => present,
        require => Package["haproxy"],
        notify => Service["haproxy"] 
    }
    ->
    service { "haproxy":
       ensure => "running",
       enable => "true",
       subscribe => File['/etc/haproxy/haproxy.cfg'],
       require => Package["haproxy"]
    }
    ->
    file { "/opt/contrail/bin/generate_haproxy.py" :
	ensure  => present,
	mode => 0755,
	group => root,
	source => "puppet:///modules/$module_name/generate_haproxy.py"
    }
    ->
    exec { "generate_ha_config" :
	command => $contrail_exec_haproxy_gen,
	cwd => "/opt/contrail/bin/",
	unless  => "grep -qx generate_ha_config /etc/contrail/contrail_openstack_exec.out",
	provider => shell,
	require => [ File["/opt/contrail/bin/generate_haproxy.py"] ],
	logoutput => $contrail_logoutput
    }


}

