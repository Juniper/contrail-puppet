define contrail::lib::post_openstack(
    $host_control_ip,
    $openstack_ip_list,
    $internal_vip,
    $contrail_logoutput = false,
) {
    if ($host_control_ip in $openstack_ip_list) {

      package { 'contrail-openstack':
	ensure  => present,
      }
      ->
      exec { "exec_start_supervisor_openstack" :
	  command => "service supervisor-openstack start && echo start_supervisor_openstack >> /etc/contrail/contrail_openstack_exec.out",
	  unless  => "grep -qx start_supervisor_openstack /etc/contrail/contrail_openstack_exec.out",
	  provider => shell,
	  require => [ Package["contrail-openstack"]  ],
	  logoutput => $contrail_logoutput
      }

      #Make ha-mon start later
      if($internal_vip != "") {
            exec { "ha-mon-restart":
                command => "service contrail-hamon restart && echo contrail-ha-mon >> /etc/contrail/contrail_openstack_exec.out",
                provider => shell,
                logoutput => $contrail_logoutput,
                unless  => "grep -qx contrail-ha-mon  /etc/contrail/contrail_openstack_exec.out",
            }
      }

    }

}
#end of upgrade-kernel
