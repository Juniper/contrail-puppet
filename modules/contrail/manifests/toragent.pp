## TODO: document the class
class contrail::toragent(
    $config_ip = $::contrail::params::config_ip_list[0],
    $contrail_tsn_ip = $::contrail::params::tsn_ip_list[0],
    $contrail_tsn_hostname = $::contrail::params::tsn_name_list[0],
    $contrail_openstack_ip = $::contrail::params::openstack_ip_list[0],
    $internal_vip = $::contrail::params::internal_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $keystone_admin_user = $::contrail::params::keystone_admin_user,
    $keystone_admin_password = $::contrail::params::keystone_admin_password,
    $keystone_admin_tenant = $::contrail::params::keystone_admin_tenant,
    $haproxy = $::contrail::params::haproxy,
    $host_control_ip = $::contrail::params::host_ip
) {
    include ::contrail
    $config_ip_to_use = $::contrail::params::config_ip_to_use
    $discovery_ip_to_use = $::contrail::params::discovery_ip_to_use

    $tor_defaults  = {
        'discovery_ip_to_use'     => $discovery_ip_to_use,
        'contrail_tsn_ip'         => $contrail_tsn_ip,
        'contrail_tsn_hostname'   => $contrail_tsn_hostname,
        'contrail_config_ip'      => $config_ip_to_use,
        'keystone_admin_user'     => $keystone_admin_user,
        'keystone_admin_password' => $keystone_admin_password,
        'keystone_admin_tenant'   => $keystone_admin_tenant,
        'contrail_openstack_ip'   => $contrail_openstack_ip,
        'host_control_ip'         => $host_control_ip,
        'product_name'            => "",
        'keepalive_time'          => '10000',
        'host_control_ip'         => $host_control_ip
    }
    $global_tor_config = $::contrail::params::tor_ha_config
    # get myhost configuration
    $tor_config = $global_tor_config["$::hostname"]
    create_resources(contrail::lib::top_of_rack, $tor_config, $tor_defaults)

    contrail::lib::report_status { 'toragent_started': state => 'toragent_started' } ->
    # directories are created by xmpp_cert_files
    file { "tor-agent-ssl-cacert" :
        ensure => $ssl_enable,
        path   => "/etc/contrail/ssl/certs/cacert.pem",
        mode   => '0755',
        owner  => root,
        group  => root,
        source => "puppet:///ssl_certs/ca-cert.pem",
    } ->
    Contrail::Lib::Top_of_rack <| |> ~>
    service { 'supervisor-vrouter':
        enable => true,
        ensure => running
    } ->
    contrail::lib::report_status { 'toragent_completed': state => 'toragent_completed' }
}
