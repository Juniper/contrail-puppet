define contrail::lib::check-os-master($openstack_master, $host_control_ip) {
	if ($host_control_ip != $openstack_master) {
		exec { "check_galera_on_master" :
			command => "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$openstack_master \'cat /etc/contrail/contrail_openstack_exec.out | grep exec_vnc_galera\' && echo check_galera_on_master >> /etc/contrail/contrail_openstack_exec.out",
				unless  => " grep -qx check_galera_on_master /etc/contrail/contrail_openstack_exec.out",
				provider => shell,
				logoutput => $contrail_logoutput
		}
        }
}
#end of check-os-master
