class contrail::control::config (
    $host_control_ip = $::contrail::params::host_ip,
    $collector_ip_port_list = $::contrail::params::collector_ip_port_list,
    $config_ip = $::contrail::params::config_ip_list[0],
    $internal_vip = $::contrail::params::internal_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $use_certs = $::contrail::params::use_certs,
    $puppet_server = $::contrail::params::puppet_server,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $config_ip_to_use = $::contrail::params::config_ip_to_use,
    $xmpp_auth_enable =  $::contrail::params::xmpp_auth_enable,
    $xmpp_dns_auth_enable =  $::contrail::params::xmpp_dns_auth_enable,
) {
    # Main class code begins here
    contain ::contrail::xmpp_cert_files
    case $::operatingsystem {
        Ubuntu: {
            # Below is temporary to work-around in Ubuntu as Service resource fails
            # as upstart is not correctly linked to /etc/init.d/service-name
            file { ['/etc/init.d/supervisor-control',
                   '/etc/init.d/supervisor-dns']:
                ensure => link,
                target => '/lib/init/upstart-job',
            } ->
            Contrail_dns_config['DEFAULT/xmpp_dns_auth_enable']
        }
    }

    if $use_certs == true {
      if $puppet_server == "" {
        $certs_store = '/etc/contrail/ssl'
      } else {
        $certs_store = '/var/lib/puppet/ssl'
      }
    } else {
      $certs_store = ''
    }

    contrail_dns_config {
      'DEFAULT/xmpp_dns_auth_enable' : value => "$xmpp_dns_auth_enable";
      'DEFAULT/hostip'    : value => $host_control_ip;
      'DEFAULT/log_file'  : value => '/var/log/contrail/dns.log';
      'DEFAULT/log_level' : value => 'SYS_NOTICE';
      'DEFAULT/log_local' : value => '1';
      'DEFAULT/collectors': value => $collector_ip_port_list;
      'IFMAP/user'        : value => "$host_control_ip.dns";
      'IFMAP/password'    : value => "$host_control_ip.dns";
      'IFMAP/certs_store' : value => "$certs_store";
    } ->
    contrail_control_config {
      'DEFAULT/xmpp_auth_enable' : value => "$xmpp_auth_enable";
      'DEFAULT/hostip'    : value => $host_control_ip;
      'DEFAULT/log_file'  : value => '/var/log/contrail/contrail-control.log';
      'DEFAULT/log_level' : value => 'SYS_NOTICE';
      'DEFAULT/log_local' : value => '1';
      'DEFAULT/collectors': value => $collector_ip_port_list;
      'IFMAP/user'        : value => "$host_control_ip";
      'IFMAP/password'    : value => "$host_control_ip";
      'IFMAP/certs_store' : value => "$certs_store";
    } ->
    contrail_control_nodemgr_config {
      'COLLECTOR/server_list'  : value => $collector_ip_port_list;
    } ->
    Class['::contrail::xmpp_cert_files']
}
