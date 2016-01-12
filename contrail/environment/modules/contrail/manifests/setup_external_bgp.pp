class contrail::setup_external_bgp (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $external_bgp =  $::contrail::params::external_bgp,
    $config_ip_to_use = $::contrail::params::config_ip_to_use,
    $router_asn =$::contrail::params::router_asn ,
    $mt_options = $::contrail::provision_contrail::mt_options
) {
    if ( $external_bgp ) {
        file { '/etc/contrail/contrail_setup_utils/setup_external_bgp.py' :
                ensure => present,
                mode   => '0755',
                group  => root,
                source => "puppet:///modules/${module_name}/setup_external_bgp.py"
        }
        ->
        exec { 'provision-external-bgp' :
                command   => "python /etc/contrail/contrail_setup_utils/setup_external_bgp.py --bgp_params \"${external_bgp}\" --api_server_ip \"${config_ip_to_use}\" --api_server_port 8082 --router_asn \"${router_asn}\" --mt_options \"${mt_options}\" && echo provision-external-bgp >> /etc/contrail/contrail_config_exec.out",
                unless    => 'grep -qx provision-external-bgp /etc/contrail/contrail_config_exec.out',
                provider  => shell,
                logoutput => $contrail_logoutput
        }
    }
    notify { "executed setup_external_bgp":; }
}

