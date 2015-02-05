class contrail::provision_complete(
    $state = undef
)
{
    $host_control_ip = $::contrail::params::host_ip
    $openstack_ip_list = $::contrail::params::openstack_ip_list

    contrail::lib::report_status { $state: state => $state }
    if ($host_control_ip in $openstack_ip_list) {

      package { 'contrail-openstack':
	ensure  => present,
      }


      exec { "exec_start_supervisor_openstack" :
	  command => "service supervisor-openstack start && echo start_supervisor_openstack >> /etc/contrail/contrail_openstack_exec.out",
	  unless  => "grep -qx start_supervisor_openstack /etc/contrail/contrail_openstack_exec.out",
	  provider => shell,
	  require => [ Package["contrail-openstack"]  ],
	  logoutput => 'true'
      }


    }

}


