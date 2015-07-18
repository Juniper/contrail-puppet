# == Class: contrail::control
#
# This class is used to configure software and services required
# to run controller module of contrail software suit.
#
# === Parameters:
#
# [*host_control_ip*]
#     IP address of the server where contrail collector is being installed.
#     if server has separate interfaces for management and control, this
#     parameter should provide control interface IP address.
#
# [*config_ip*]
#     Control interface IP address of the server where config module of
#     contrail cluster is configured. If there are multiple config nodes
#     , IP address of first config node server is specified here.
#
# [*internal_vip*]
#     Virtual IP on the control/data interface (internal network) to be used for openstack.
#     (optional) - Defaults to "".
#
# [*contrail_internal_vip*]
#     Virtual IP on the control/data interface (internal network) to be used for contrail.
#     (optional) - Defaults to "".
#
# [*use_certs*]
#     Flag to indicate whether to use certificates for authentication.
#     (optional) - Defaults to False.
#
# [*puppet_server*]
#     FQDN of puppet master, in case puppet master is used for certificates
#     (optional) - Defaults to "".
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::control (
    $host_control_ip = $::contrail::params::host_ip,
    $config_ip = $::contrail::params::config_ip_list[0],
    $internal_vip = $::contrail::params::internal_vip,
    $contrail_internal_vip = $::contrail::params::contrail_internal_vip,
    $use_certs = $::contrail::params::use_certs,
    $puppet_server = $::contrail::params::puppet_server,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) inherits ::contrail::params {

    # If internal VIP is configured, use that address as config_ip.
    if ($contrail_internal_vip != '') {
        $config_ip_to_use = $contrail_internal_vip
    } elsif ($internal_vip != '') {
        $config_ip_to_use = $internal_vip
    } else {
        $config_ip_to_use = $config_ip
    }

    # Main class code begins here
    case $::operatingsystem {
        Ubuntu: {
                file { ['/etc/init/supervisor-control.override',
                        '/etc/init/supervisor-dns.override'] :
                    ensure  => absent,
                    require => Package['contrail-openstack-control']
                }
            #TODO, Is this really needed?
                service { 'supervisor-dns' :
                    ensure    => running,
                    enable    => true,
                    require   => [ Package['contrail-openstack-control'] ],
                    subscribe => File['/etc/contrail/contrail-dns.conf'],
                }
                # Below is temporary to work-around in Ubuntu as Service resource fails
                # as upstart is not correctly linked to /etc/init.d/service-name
            file { '/etc/init.d/supervisor-control':
                ensure => link,
                target => '/lib/init/upstart-job',
                before => Service['supervisor-control']
            }
            file { '/etc/init.d/supervisor-dns':
                ensure => link,
                target => '/lib/init/upstart-job',
                before => Service['supervisor-dns']
            }
        }
        default: {
        }
    }
    contrail::lib::report_status { 'control_started':
        state              => 'control_started',
        contrail_logoutput => $contrail_logoutput
    }
    ->
    # Ensure all needed packages are present
    package { 'contrail-openstack-control' : ensure => latest, notify => 'Service[supervisor-control]'}
    ->

    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - supervisor, contrail-api-lib, contrail-control, contrail-dns,
    #                      contrail-setup, contrail-nodemgr
    # For Centos/Fedora - contrail-api-lib, contrail-control, contrail-setup, contrail-libs
    #                     contrail-dns, supervisor


    # Ensure all config files with correct content are present.
    file { '/etc/contrail/contrail-dns.conf' :
        ensure  => present,
        require => Package['contrail-openstack-control'],
        content => template("${module_name}/contrail-dns.conf.erb"),
    }
    ->
    file { '/etc/contrail/contrail-control.conf' :
        ensure  => present,
        require => Package['contrail-openstack-control'],
        content => template("${module_name}/contrail-control.conf.erb"),
    }
    ->
    file { '/etc/contrail/contrail-control-nodemgr.conf' :
        ensure  => present,
        require => Package['contrail-openstack-control'],
        content => template("${module_name}/contrail-control-nodemgr.conf.erb"),
    }

    # The below script can be avoided. Sets up puppet agent and waits to get certificate from puppet master.
    # also has service restarts for puppet agent and supervisor-control. Abhay
    #->
    #file { "/opt/contrail/contrail_installer/contrail_setup_utils/control-server-setup.sh":
    #    ensure  => present,
    #    mode => 0755,
    #    owner => root,
    #    group => root,
    #}
    #->
    #exec { "control-server-setup" :
    #    command => "/opt/contrail/contrail_installer/contrail_setup_utils/control-server-setup.sh; echo control-server-setup >> /etc/contrail/contrail_control_exec.out",
    #    require => File["/opt/contrail/contrail_installer/contrail_setup_utils/control-server-setup.sh"],
    #    unless  => "grep -qx control-server-setup /etc/contrail/contrail_control_exec.out",
    #    provider => shell,
    #    logoutput => $contrail_logoutput
    #}
    ->
    # update rndc conf
    exec { 'update-rndc-conf-file' :
        command   => "sudo sed -i 's/secret \"secret123\"/secret \"xvysmOR8lnUQRBcunkC6vg==\"/g' /etc/contrail/dns/rndc.conf && echo update-rndc-conf-file >> /etc/contrail/contrail_control_exec.out",
        require   => package['contrail-openstack-control'],
        onlyif    => 'test -f /etc/contrail/dns/rndc.conf',
        unless    => 'grep -qx update-rndc-conf-file /etc/contrail/contrail_control_exec.out',
        provider  => shell,
        logoutput => $contrail_logoutput
    }
    # Ensure the services needed are running.
    ->
    service { 'supervisor-control' :
        ensure    => running,
        enable    => true,
        require   => [ Package['contrail-openstack-control'] ],
        subscribe => File['/etc/contrail/contrail-control.conf'],
    }
    ->
    service { 'contrail-named' :
        ensure    => running,
        enable    => true,
        require   => [ Package['contrail-openstack-control'] ],
        subscribe => File['/etc/contrail/contrail-dns.conf'],
    }
    ->
    contrail::lib::report_status { 'control_completed':
        state              => 'control_completed',
        contrail_logoutput => $contrail_logoutput
    }
}
