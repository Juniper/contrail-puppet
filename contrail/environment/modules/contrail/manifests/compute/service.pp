class contrail::compute::service(
  $nova_compute_status = $::contrail::compute::config::nova_compute_status,
  $host_control_ip = $::contrail::params::host_ip,
  $compute_ip_list = $::contrail::params::compute_ip_list,
  $nfs_server = $::contrail::params::nfs_server,
  $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    service { 'nova-compute' :
        enable => $nova_compute_status,
        ensure => $nova_compute_status,
    }
    ## Same condition as compute/config.pp
    if ($nfs_server == 'xxx' and $host_control_ip == $compute_ip_list[0] ) {
       Service['nova-compute']->
       service { 'nfs-kernel-server':
         ensure => running,
         enable => true
       }
    }
}
