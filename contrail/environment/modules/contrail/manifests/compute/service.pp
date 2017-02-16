class contrail::compute::service(
  $nova_compute_status = $::contrail::compute::config::nova_compute_status,
  $host_control_ip     = $::contrail::params::host_ip,
  $compute_ip_list     = $::contrail::params::compute_ip_list,
  $nfs_server          = $::contrail::params::nfs_server,
  $contrail_logoutput  = $::contrail::params::contrail_logoutput,
  $upgrade_needed      = $::contrail::params::upgrade_needed,
  $enable_ceilometer   = $::contrail::params::enable_ceilometer,
) {
    if !('toragent' in $contrail::params::host_roles) {
        service { 'supervisor-vrouter':
            ensure  => running,
            enable  => true,
        }
    }
    if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
        $nova_service_name = "openstack-nova-compute"
        exec { 'sevc-openstk-nova-restart' :
            command => "service ${nova_service_name} restart",
            provider => shell,
            logoutput => $contrail_logoutput,
        }
    } else {
        $nova_service_name = "nova-compute"
    }
    service { $nova_service_name :
        enable => $nova_compute_status,
        ensure => $nova_compute_status,
        subscribe => Exec['setup-compute-server-setup']
    }

    ## Same condition as compute/config.pp
    if ($nfs_server == 'xxx' and $host_control_ip == $compute_ip_list[0] ) {
       Service[$nova_service_name]->
       service { 'nfs-kernel-server':
         ensure => running,
         enable => true
       }
    }
    if ($upgrade_needed == 1) {
        exec { 'upgrade-vrouter-restart' :
            command => "rmmod vrouter && service supervisor-vrouter restart",
            provider => shell,
            logoutput => $contrail_logoutput,
        }
    }
}
