define contrail::lib::post_openstack($host_control_ip, $openstack_ip_list, $internal_vip) {
    if ($host_control_ip in $openstack_ip_list) {
/*
      package { 'contrail-openstack':
	ensure  => present,
      }
      ->
      exec { "exec_start_supervisor_openstack" :
	  command => "service supervisor-openstack start && echo start_supervisor_openstack >> /etc/contrail/contrail_openstack_exec.out",
	  unless  => "grep -qx start_supervisor_openstack /etc/contrail/contrail_openstack_exec.out",
	  provider => shell,
	  require => [ Package["contrail-openstack"]  ],
	  logoutput => 'true'
      }
*/
      #Make ha-mon start later
      if($internal_vip != "") {
            $openstack_mgmt_ip_list = $::contrail::params::openstack_mgmt_ip_list_to_use
            $openstack_passwd_list = $::contrail::params::openstack_passwd_list
            $openstack_user_list = $::contrail::params::openstack_user_list

            $os_master = $openstack_mgmt_ip_list[0]
            $os_username = $openstack_user_list[0]
            $os_passwd = $openstack_passwd_list[0]

#move to provision complete
	    file { "/opt/contrail/bin/transfer_keys.py":
	       ensure  => present,
	       mode => 0755,
	       owner => root,
	       group => root,
	       source => "puppet:///modules/$module_name/transfer_keys.py"
	    }
	    ->
	    exec { "exec-transfer-keys":
		    command => "python /opt/contrail/bin/transfer_keys.py $os_master \"/etc/ssl/\" $os_username $os_passwd && echo exec-transfer-keys >> /etc/contrail/contrail_ha_exec.out",
		    provider => shell,
		    logoutput => "true",
		    unless  => "grep -qx exec-transfer-keys  /etc/contrail/contrail_ha_exec.out",
		    require => File["/opt/contrail/bin/transfer_keys.py"]
	    }
	    ->
            exec { "ha-mon-restart":
                command => "service contrail-hamon restart && echo contrail-ha-mon >> /etc/contrail/contrail_openstack_exec.out",
                provider => shell,
                logoutput => "true",
                unless  => "grep -qx contrail-ha-mon  /etc/contrail/contrail_openstack_exec.out",
            }
      }

    }

}
#end of upgrade-kernel
