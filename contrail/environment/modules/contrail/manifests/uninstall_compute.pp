# This class is used to configure software and services required
# to run compute module (vrouter and agent) of contrail software suit.
#
# === Parameters:
#
# [*host_control_ip*]
#     IP address of the server.
#     If server has separate interfaces for management and control, this
#     parameter should provide control interface IP address.
#
# [*openstack_ip*]
#     IP address of server running openstack services. If the server has
#     separate interfaces for management and control, this parameter
#     should provide control interface IP address.
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::uninstall_compute (
    $host_control_ip = $::contrail::params::host_ip,
    $config_ip_to_use = $::contrail::params::config_ip_to_use, 
    $openstack_ip = $::contrail::params::openstack_ip_list[0],
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $contrail_host_roles = $::contrail::params::host_roles,
    $enable_lbass =  $::contrail::params::enable_lbass,
) inherits ::contrail::params {

    # Debug Print all variable values
    notify {'host_control_ip = $host_control_ip':; } ->
    notify {'openstack_ip = $openstack_ip':; } ->
    notify {'config_ip_to_use = $config_ip_to_use':; } 

    #Determine vrouter package to be installed based on the kernel
    #TODO add DPDK support here


    if ($operatingsystem == 'Ubuntu'){

        if ($lsbdistrelease == '14.04') {
            if ($kernelrelease == '3.13.0-40-generic') {
            	$vrouter_pkg = 'contrail-vrouter-3.13.0-40-generic' 
            } else {
            	$vrouter_pkg = 'contrail-vrouter-dkms' 
            }
        } elsif ($lsbdistrelease == '12.04') {
            if ($kernelrelease == '3.13.0-34-generic') {
            	$vrouter_pkg = 'contrail-vrouter-3.13.0-34-generic' 
            } else {
            	$vrouter_pkg = 'contrail-vrouter-dkms' 
            }
        }
    }
    else {
      	$vrouter_pkg = 'contrail-vrouter' 
    }


    contrail::lib::report_status { 'uninstall_compute_started':
        state => 'uninstall_compute_started', 
        contrail_logoutput => $contrail_logoutput }
    ->
    class {'::contrail::delete_vnc_config':
           config_ip_to_use => $config_ip_to_use,
           host_control_ip => $host_control_ip,
           keystone_admin_user => $keystone_admin_user,
           keystone_admin_password => $keystone_admin_password
    }
    ->
    service { 'supervisor-vrouter' :
	enable => false,
	ensure => stopped,
    }
    ->
    file { '/etc/network/interfaces':
          ensure => present,
          source => '/etc/network/interfaces.orig',
    }
    ->
   # Main code for class starts here
    # Ensure all needed packages are latest
    package { $vrouter_pkg : ensure => purged, notify => ['Exec[apt_auto_remove_compute]']}->
    package { 'contrail-openstack-vrouter' : ensure => purged, notify => ['Exec[apt_auto_remove_compute]']}

    if ($enable_lbass == true) {
        package{'haproxy': ensure => purged, notify => ['Exec[apt_auto_remove_compute]']} ->
        package{'iproute': ensure => purged, notify => ['Exec[apt_auto_remove_compute]']}

    }

    #The below way should be the ideal one,
    #But when vrouter-agent starts , the actual physical interface is not removed,
    #when vhost comes up.
    #This results in non-reachablity
    #package { 'contrail-openstack-vrouter' : ensure => latest, notify => 'Service[supervisor-vrouter]'}



    exec { 'apt_auto_remove_compute':
        command => 'apt-get autoremove -y --purge',
        provider => shell,
        logoutput => $contrail_logoutput
    }
    ->
    file { ['/etc/contrail/contrail_setup_utils/add_dev_tun_in_cgroup_device_acl.sh',
            '/etc/contrail/vrouter_nodemgr_param',
            '/etc/contrail/default_pmac', 
            '/etc/contrail/agent_param',
            '/etc/contrail/contrail-vrouter-agent.conf',
            '/etc/contrail/contrail-vrouter-nodemgr.conf',
           ]:
        ensure  => absent,
    } ->
    
    contrail::lib::report_status { 'compute_completed':
            state => 'compute_completed', 
            contrail_logoutput => $contrail_logoutput }
    ->
    class {'::contrail::clear_compute':}
    ->
    class {'::contrail::do_reboot_server':
        reboot_flag => 'uninstall_compute_reboot',
    }
}
