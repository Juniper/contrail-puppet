define contrail::lib::post_openstack(
    $host_control_ip,
    $openstack_ip_list,
    $internal_vip,
    $contrail_logoutput = false,
) {
    if ($host_control_ip in $openstack_ip_list) {

      package { 'contrail-openstack':
	ensure  => latest,
      }
      ->
      exec { "exec_start_supervisor_openstack" :
	  command => "service supervisor-openstack restart && echo start_supervisor_openstack >> /etc/contrail/contrail_openstack_exec.out",
          unless  => "grep -qx start_supervisor_openstack /etc/contrail/contrail_openstack_exec.out",
	  provider => shell,
	  require => [ Package["contrail-openstack"]  ],
	  logoutput => $contrail_logoutput
      }

      #Make ha-mon start later
      if($internal_vip != "") {
            #Get the value for hiera and not from openstack::config
            #as with sequencing changes openstack modules is disabled after its
            #step is completed.

            $password = hiera(openstack::mysql::service_password)
            exec { "ha-mon-restart":
                command => "service contrail-hamon restart && echo contrail-ha-mon >> /etc/contrail/contrail_openstack_exec.out",
                provider => shell,
                before => "Exec[exec_start_supervisor_openstack]",
                logoutput => $contrail_logoutput,
                unless  => "grep -qx contrail-ha-mon  /etc/contrail/contrail_openstack_exec.out",
            }

           # Set mysql cpnnection string at the end
           # as setting before will result in provision failure.
           # Openstack is setup before galera is setup.
           # Intiailly mysql connection string is setup to internal_vip:3306,
           # making all mysql commands to land on vip node.
           # Later mysql needs to change to localip to support failover scenarios.
           # If mysql connection string is setup to local_ip while provisoning openstack.
           # openstack 2,3 provision will fail as db-sync is done only on 1, 
           # and they dont find the tables.

	    exec { "exec_set_mysql":
		    command => "openstack-config --set /etc/keystone/keystone.conf database connection mysql://keystone:$password@$host_control_ip/keystone  && 
                           openstack-config --set /etc/keystone/keystone.conf sql connection mysql://keystone:$password@$host_control_ip/keystone && 
                           openstack-config --set /etc/cinder/cinder.conf database connection mysql://cinder:$password@$host_control_ip/cinder && 
                           openstack-config --set /etc/glance/glance-registry.conf database connection mysql://glance:$password@$host_control_ip/glance && 
                           openstack-config --set /etc/glance/glance-api.conf database connection mysql://glance:$password@$host_control_ip/glance && 
                           openstack-config --set /etc/neutron/neutron.conf database connection mysql://neutron:$password@$host_control_ip/neutron && 
                           echo exec_set_mysql >> /etc/contrail/contrail_openstack_exec.out",
		    provider => shell,
                    before => "Exec[exec_start_supervisor_openstack]",
		    logoutput => $contrail_logoutput
	    }

      }

    }

}
#end of upgrade-kernel
