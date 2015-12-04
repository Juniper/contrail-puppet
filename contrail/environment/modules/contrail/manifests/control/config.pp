class contrail::control::config (
    $host_control_ip = $::contrail::params::host_ip,
    $config_ip = $::contrail::params::config_ip_list[0],
    $internal_vip = $::contrail::params::internal_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $use_certs = $::contrail::params::use_certs,
    $puppet_server = $::contrail::params::puppet_server,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $config_ip_to_use = $::contrail::params::config_ip_to_use
) {
    # Main class code begins here
    case $::operatingsystem {
        Ubuntu: {
            # Below is temporary to work-around in Ubuntu as Service resource fails
            # as upstart is not correctly linked to /etc/init.d/service-name
            file { ['/etc/init.d/supervisor-control',
                   '/etc/init.d/supervisor-dns']:
                ensure => link,
                target => '/lib/init/upstart-job',
            }
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
      'DEFAULT/hostip'    : value => $host_control_ip;
      'DEFAULT/log_file'  : value => '/var/log/contrail/dns.log';
      'DEFAULT/log_level' : value => 'SYS_NOTICE';
      'DEFAULT/log_local' : value => '1';
      'DISCOVERY/server'  : value => $config_ip_to_use;
      'IFMAP/user'        : value => "$host_control_ip.dns";
      'IFMAP/password'    : value => "$host_control_ip.dns";
      'IFMAP/certs_store' : value => "$certs_store";
    }

    contrail_control_config {
      'DEFAULT/hostip'    : value => $host_control_ip;
      'DEFAULT/log_file'  : value => '/var/log/contrail/contrail-control.log';
      'DEFAULT/log_level' : value => 'SYS_NOTICE';
      'DEFAULT/log_local' : value => '1';
      'DISCOVERY/server'  : value => $config_ip_to_use;
      'IFMAP/user'        : value => "$host_control_ip";
      'IFMAP/password'    : value => "$host_control_ip";
      'IFMAP/certs_store' : value => "$certs_store";
    }

    contrail_control_nodemgr_config {
      'DISCOVERY/server'  : value => $config_ip_to_use;
      'DISCOVERY/port'    : value => '5998';
    }
}
