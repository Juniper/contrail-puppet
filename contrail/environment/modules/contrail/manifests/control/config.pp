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
            file { ['/etc/init/supervisor-control.override',
                    '/etc/init/supervisor-dns.override'] :
                ensure  => absent,
            }
            ->
            # Below is temporary to work-around in Ubuntu as Service resource fails
            # as upstart is not correctly linked to /etc/init.d/service-name
            file { ['/etc/init.d/supervisor-control',
                   '/etc/init.d/supervisor-dns']:
                ensure => link,
                target => '/lib/init/upstart-job',
            }
            ->
            File['/etc/contrail/contrail-dns.conf']
        }
        default: {
        }
    }
    # Ensure all config files with correct content are present.
    file { '/etc/contrail/contrail-dns.conf' :
        ensure  => present,
        content => template("${module_name}/contrail-dns.conf.erb"),
    }
    ->
    file { '/etc/contrail/contrail-control.conf' :
        ensure  => present,
        content => template("${module_name}/contrail-control.conf.erb"),
    }
    ->
    file { '/etc/contrail/contrail-control-nodemgr.conf' :
        ensure  => present,
        content => template("${module_name}/contrail-control-nodemgr.conf.erb"),
    }
    ->
    # update rndc conf
    exec { 'update-rndc-conf-file' :
        command   => "sudo sed -i 's/secret \"secret123\"/secret \"xvysmOR8lnUQRBcunkC6vg==\"/g' /etc/contrail/dns/rndc.conf && echo update-rndc-conf-file >> /etc/contrail/contrail_control_exec.out",
        onlyif    => 'test -f /etc/contrail/dns/rndc.conf',
        unless    => 'grep -qx update-rndc-conf-file /etc/contrail/contrail_control_exec.out',
        provider  => shell,
        logoutput => $contrail_logoutput
    }
}
