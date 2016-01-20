define contrail::lib::setup_coremask(
    $contrail_logoutput = false,
    $core_mask= $::contrail::params::core_mask,
    $enable_dpdk = $::contrail::params::enable_dpdk,
) {

   if ($enable_dpdk) {
     if ( ',' in coremask or '-' in coremask ) {
       $taskset_params = " -C"
     } else {
       $taskset_params = ""
     }

     $vrouter_file = '/etc/contrail/supervisord_vrouter_files/contrail-vrouter-dpdk.ini'

     #try startuing a dummy task with coremask,
     #if that goes through set in the supervisor file.
     exec { 'try_core_mask' :
       command   => "taskset${taskset_params} ${core_mask} true",
       provider  => 'shell',
       logoutput => $contrail_logoutput
     } ->
     #unable to use file_line as it works only on whole
     #lines and not on wordS
     exec { 'change_supervisor' :
       command   => "sed -i \"s/command=/command=taskset${taskset_params} ${core_mask} /g\" ${vrouter_file}",
       provider  => 'shell',
       logoutput => $contrail_logoutput
     }
   }

}
