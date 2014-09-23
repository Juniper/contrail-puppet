class __$version__::contrail_openstack {

define openstack-scripts {
    file { "/opt/contrail/contrail_installer/contrail_setup_utils/${title}.sh":
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
    }
    exec { "setup-${title}" :
        command => "/opt/contrail/contrail_installer/contrail_setup_utils/${title}.sh $operatingsystem && echo setup-${title} >> /etc/contrail/contrail_openstack_exec.out",
        require => [ File["/opt/contrail/contrail_installer/contrail_setup_utils/${title}.sh"],
                     File["/etc/contrail/ctrl-details"] ],
        unless  => "grep -qx setup-${title} /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => "true"
    }
}

define check_keep_alived() {
	if ($contrail_openstack_index != "1" ) {
            exec { "check-keepalived":
                command => "ping -c 5 $internal_vip && echo check_keepalived >> /etc/contrail/contrail_openstack_exec.out",
                require => package["contrail-openstack-ha"],
                unless  => "grep -qx check_keepalived /etc/contrail/contrail_openstack_exec.out",
                provider => shell,
                logoutput => "true"
            }
	}

}

define openstack_hacks() {
    exec { "openstack_hacks" :
        command => "openstack-config --set /etc/nova/nova.conf DEFAULT neutron_url http://$internal_vip:9696/ && openstack-config --set /etc/nova/nova.conf DEFAULT neutron_admin_auth_url http://$internal_vip:5000/v2.0/ && service supervisor-openstack restart && echo openstack_hacks >> /etc/contrail/contrail_openstack_exec.out",
        unless  => "grep -qx openstack_hacks /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => "true"
    }



}

define check_mysql_state() {
	if ($contrail_openstack_index != "1" ) {
	    # check_mysql
	    file { "/opt/contrail/contrail_installer/verify_gallera_master.py" :
		ensure  => present,
		mode => 0755,
		group => root,
		source => "puppet:///modules/$module_name/verify_gallera_master.py"
	    }

->
	    exec { "exec_check_gallera" :
		command => "python /opt/contrail/contrail_installer/verify_gallera_master.py $os_master $os_username $os_password && echo check_mysql >> /etc/contrail/contrail_openstack_exec.out",
		unless  => "grep -qx check_mysql /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		require => [ File["/opt/contrail/contrail_installer/verify_gallera_master.py"] ],
		logoutput => 'true'
	    }
	}
}

define fix_rabbitmq_os() {
/*
	if($internal_vip != "") {

            exec { "rabbit_os_fix":
                command => "rabbitmqctl set_policy HA-all \"\" '{\"ha-mode\":\"all\",\"ha-sync-mode\":\"automatic\"}' && echo rabbit_os_fix >> /etc/contrail/contrail_openstack_exec.out",
                require => package["contrail-openstack-ha"],
                unless  => "grep -qx rabbit_os_fix /etc/contrail/contrail_openstack_exec.out",
                provider => shell,
                logoutput => "true"
            }

	}

if ! defined(File["/opt/contrail/contrail_installer/set_rabbit_tcp_params.py"]) {

	    # check_wsrep
	    file { "/opt/contrail/contrail_installer/set_rabbit_tcp_params.py" :
		ensure  => present,
		mode => 0755,
		group => root,
		source => "puppet:///modules/$module_name/set_rabbit_tcp_params.py"
	    }


	    exec { "exec_set_rabbitmq_tcp_params" :
		command => "python /opt/contrail/contrail_installer/set_rabbit_tcp_params.py",
		cwd => "/opt/contrail/contrail_installer/",
		unless  => "grep -qx exec_set_rabbitmq_tcp_params /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		require => [ File["/opt/contrail/contrail_installer/set_rabbit_tcp_params.py"] ],
		logoutput => 'true'
	    }
}
*/
}

define fix-wsrep() {

	if ($contrail_openstack_index == "1" ) {

	    # Fix WSREP cluster address
	    # Need check this from provisioned ha box 
	    exec { "fix_wsrep_cluster_address" :
		command => "sudo sed -ibak 's#wsrep_cluster_address=.*#wsrep_cluster_address=gcomm://$openstack_ip_list_wsrep#g' $wsrep_conf && echo exec_fix_wsrep_cluster_address >> /etc/contrail/contrail_openstack_exec.out",
		require =>  package["contrail-openstack"],
		onlyif => "test -f $wsrep_conf",
		unless  => "grep -qx exec_fix_wsrep_cluster_address /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		logoutput => 'true',
		before => Service["mysqld"]
	    }
	}
}

define setup-haproxy-config() {
            file { "/etc/haproxy/haproxy.cfg.os":
                ensure  => present,
                mode => 0755,
                owner => root,
                group => root,
                source => "puppet:///modules/$module_name/$hostname.cfg"
            }
 ->
            exec { "haproxy-exec-os":
                command => "sudo sed -i 's/ENABLED=.*/ENABLED=1/g' /etc/default/haproxy && mv /etc/haproxy/haproxy.cfg.os /etc/haproxy/haproxy.cfg && service haproxy restart && chkconfig haproxy on && echo haproxy-exec-os >> /etc/contrail/contrail_openstack_exec.out",
                require => File["/etc/haproxy/haproxy.cfg.os"],
                unless  => "grep -qx haproxy-exec-os /etc/contrail/contrail_openstack_exec.out",
                provider => shell,
                logoutput => "true"
            }
}

define setup-ha($internal_vip) {
	    notify { "contrail intenal_vip  is '$internal_vip' ":; }
        if ($internal_vip != '' and $internal_vip != 'none') {

	    if ($operatingsystem == "Ubuntu") {
		$wsrep_conf='/etc/mysql/conf.d/wsrep.cnf'
	    } else {
		$wsrep_conf='/etc/mysql/my.cnf'
	    } 

            $glance_path ="/var"

            #$openstack_ip_list_wsrep_cpy = $openstack_ip_list
            $openstack_pass_list_shell = inline_template('<%= openstack_password_list.map{ |name1| "#{name1}" }.join(",") %>')
            $openstack_ip_list_control_shell = inline_template('<%= openstack_ip_list_control.map{ |name2| "#{name2}" }.join(" ") %>')
            #$openstack_ip_list_wsrep = ""# inline_template('<%= openstack_ip_list_wsrep_cpy.map{ |name3| name3.concat(":4567") } %>')
            #$openstack_ip_list_wsrep_shell = "" # inline_template('<%= openstack_ip_list_wsrep.map{ |name4| "#{name}4" }.join(",") %>')
	    #$test1 = inline_template('<%= openstack_ip_list_wsrep_cpy.map{ |name3| name3.concat(":4567") } %>')


            $openstack_ip_list_shell = inline_template('<%= openstack_ip_list.map{ |ip| "#{ip}" }.join(",") %>')
            $openstack_user_list_shell = inline_template('<%= openstack_user_list.map{ |ip| "#{ip}" }.join(",") %>')
            $openstack_password_list_shell = inline_template('<%= openstack_password_list.map{ |ip| "#{ip}" }.join(",") %>')


	    $contrail_exec_password_less_ssh = "python /opt/contrail/contrail_installer/setup_passwordless_ssh.py $openstack_ip_list_shell $openstack_user_list_shell $openstack_pass_list_shell && echo exec-setup-password-less-ssh >> /etc/contrail/contrail_openstack_exec.out"

	    $contrail_exec_vnc_galera = "PASSWORD=$root_password ADMIN_TOKEN=$contrail_service_token python setup-vnc-galera.py --self_ip $self_ip --keystone_ip $contrail_openstack_mgmt_ip --galera_ip_list $openstack_ip_list_control_shell --internal_vip $internal_vip --openstack_index $contrail_openstack_index && echo exec_vnc_galera >> /etc/contrail/contrail_openstack_exec.out"


	    $contrail_exec_check_wsrep = "python check-wsrep-status.py $openstack_ip_list_shell  && echo check-wsrep >> /etc/contrail/contrail_openstack_exec.out"


	    $contrail_exec_setup_cmon_schema = "python setup-cmon-schema.py $os_master $self_ip $internal_vip  && echo exec_setup_cmon_schema >> /etc/contrail/contrail_openstack_exec.out"

	    $contrail_exec_vnc_keepalived = "PASSWORD=$root_password ADMIN_TOKEN=$contrail_service_token python setup-vnc-keepalived.py --self_ip $self_ip --internal_vip $internal_vip --mgmt_self_ip $contrail_openstack_mgmt_ip --self_index $contrail_openstack_index --num_nodes $openstack_num_nodes --role openstack && echo exec_vnc_keepalived >> /etc/contrail/contrail_openstack_exec.out"

	    notify { "contrail wsrep debug  is $openstack_ip_list_wsrep":; }
#	    notify { "contrail wsrep debug  is $openstack_ip_list_wsrep_cpy , $openstack_ip_list_wsrep, $openstack_ip_list_wsrep_shell ":; }


    setup-openstack-ha{setup_openstack_ha:
	}
->

	    # KEEPALIVED
	    file { "/opt/contrail/contrail_installer/setup-vnc-keepalived.py" :
		ensure  => present,
		mode => 0755,
		group => root,
		#source => "puppet:///modules/$module_name/exec_provision_control.py"
	    }
#->
#	    notify { "contrail exec_vnc_keepalived is $contrail_exec_vnc_keepalived":; } 

->
	check_keep_alived{'check_keep_alived':}

->
	    exec { "exec_enable_haproxy" :
                command => "sudo sed -i 's/ENABLED=.*/ENABLED=1/g' /etc/default/haproxy && service haproxy start && echo exec_enable_haproxy >> /etc/contrail/contrail_openstack_exec.out",
                require => package['contrail-openstack-ha'] ,
                unless  => "grep -qx exec_enable_haproxy /etc/contrail/contrail_openstack_exec.out",
                provider => shell,
                logoutput => "true"
	    }

->
	    exec { "exec_vnc_keepalived" :
		command => $contrail_exec_vnc_keepalived,
		cwd => "/opt/contrail/contrail_installer/",
		unless  => "grep -qx exec_vnc_keepalived /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		require => [ File["/opt/contrail/contrail_installer/setup-vnc-keepalived.py"] ],
		logoutput => 'true'
	    }
->
	    #########Chhandak-HA
	    # GALERA
	    file { "/opt/contrail/contrail_installer/setup_passwordless_ssh.py" :
		ensure  => present,
		mode =>	0755,
		group => root,
		source => "puppet:///modules/$module_name/setup_passwordless_ssh.py"
	    }
#->
#	    notify { "contrail exec_password_less_ssh is $contrail_exec_password_less_ssh":; }
->

	    #Keystoen hack
	    exec { "keystone-hack" :
		command => "openstack-config --set /etc/keystone/keystone.conf DEFAULT public_port 6000 && openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_port 35358 && echo exec-keystone-hack >> /etc/contrail/contrail_openstack_exec.out",
		unless  => "grep -qx exec-keystone-hack /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		require => package["contrail-openstack-ha"],
		logoutput => 'true'
	    }

->
	    exec { "exec_password_less_ssh" :
		command => $contrail_exec_password_less_ssh,
		cwd => "/opt/contrail/contrail_installer/",
		unless  => "grep -qx exec-setup-password-less-ssh /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		require => [ File["/opt/contrail/contrail_installer/setup_passwordless_ssh.py"] ],
		logoutput => 'true'
	    }
->

	    file { "/opt/contrail/contrail_installer/setup-vnc-galera.py" :
		ensure  => present,
		mode =>	0755,
		group => root,
		#source => "puppet:///modules/$module_name/exec_provision_control.py"
	    }
#	    notify { "contrail exec_vnc_galera is $contrail_exec_vnc_galera":; }
->
	    check_mysql_state{'check_mysql_state':}
->
	    exec { "exec_vnc_galera" :
		command => $contrail_exec_vnc_galera,
		cwd => "/opt/contrail/contrail_installer/",
		unless  => "grep -qx exec_vnc_galera /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		require => [ File["/opt/contrail/contrail_installer/setup-vnc-galera.py"] ],
		logoutput => 'true'
	    }

->
	    # check_wsrep
	    file { "/opt/contrail/contrail_installer/check-wsrep-status.py" :
		ensure  => present,
		mode => 0755,
		group => root,
		source => "puppet:///modules/$module_name/check-wsrep-status.py"
	    }

->

	    #notify { "contrail exec-check-wsrep is $contrail_exec_check_wsrep":; } 
	    exec { "exec_check_wsrep" :
		command => $contrail_exec_check_wsrep,
		cwd => "/opt/contrail/contrail_installer/",
		unless  => "grep -qx check-wsrep /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		require => [ File["/opt/contrail/contrail_installer/check-wsrep-status.py"] ],
		logoutput => 'true'
	    }

->

	    # check_galera
	    file { "/opt/contrail/contrail_installer/check_galera.py" :
		ensure  => present,
		mode => 0755,
		group => root,
		source => "puppet:///modules/$module_name/check_galera.py"
	    }

->
	    exec { "exec_check_galera" :
		command => "python /opt/contrail/contrail_installer/check_galera.py $openstack_ip_list_shell $openstack_user_list_shell $openstack_password_list_shell && echo check_galera >> /etc/contrail/contrail_openstack_exec.out",
		cwd => "/opt/contrail/contrail_installer/",
		unless  => "grep -qx check_galera /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		require => [ File["/opt/contrail/contrail_installer/check_galera.py"] ],
		logoutput => 'true'
	    }

->


fix-wsrep{'fix_wsrep':}
->
	    # setup_cmon
	    file { "/opt/contrail/contrail_installer/setup-cmon-schema.py" :
		ensure  => present,
		mode => 0755,
		group => root,
		source => "puppet:///modules/$module_name/setup-cmon-schema.py"
	    }
#->
#	    notify { "contrail exec-setup-cmon-schema is $contrail_exec_setup_cmon_schema":; } 
->
	    exec { "exec_setup_cmon_schema" :
		command => $contrail_exec_setup_cmon_schema,
		cwd => "/opt/contrail/contrail_installer/",
		unless  => "grep -qx exec_setup_cmon_schema /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		require => [ File["/opt/contrail/contrail_installer/setup-cmon-schema.py"] ],
		logoutput => 'true'
	    }
->
	    exec { "fix_xinetd_conf" :
		command => "sed -i -e 's#only_from = 0.0.0.0/0#only_from = $self_ip 127.0.0.1#' /etc/xinetd.d/contrail-mysqlprobe && service xinetd restart && chkconfig xinetd on && echo fix_xinetd_conf >> /etc/contrail/contrail_openstack_exec.out",
		require =>  package["contrail-openstack"],
		unless  => "grep -qx fix_xinetd_conf  /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		logoutput => 'true',
		before => Service["mysqld"]



	    }
->
	    setup-haproxy-config {'setup_haproxy_config':}
#->
/*
    	    mount-nfs {mount_nfs:
		nfs_server => $nfs_server,
		glance_path => $glance_path	
	    }
*/
->
	    fix-memcache-conf{fix_memcache_conf:}
->

	    fix-cmon-param-and-copy-ssh {'fix_cmon_param_and_copy_ssh':}
	    #########Chhandak-HA End Here
} elsif (($contrail_internal_vip != '') and
         ($contrail_internal_vip != 'none')){

	    $contrail_exec_vnc_keepalived = "PASSWORD=$root_password ADMIN_TOKEN=$contrail_service_token python setup-vnc-keepalived.py --self_ip $self_ip --internal_vip $internal_vip --mgmt_self_ip $contrail_openstack_mgmt_ip --self_index $contrail_openstack_index --num_nodes $openstack_num_nodes --role openstack && echo exec_vnc_keepalived >> /etc/contrail/contrail_openstack_exec.out"
	    # KEEPALIVED




	    file { "/opt/contrail/contrail_installer/setup-vnc-keepalived.py" :
		ensure  => present,
		mode => 0755,
		group => root,
		#source => "puppet:///modules/$module_name/exec_provision_control.py"
	    }
#->
#	    notify { "contrail exec_vnc_keepalived is $contrail_exec_vnc_keepalived":; } 
->
	check_keep_alived{'check_keep_alived':}
->
	    exec { "exec_vnc_keepalived" :
		command => $contrail_exec_vnc_keepalived,
		cwd => "/opt/contrail/contrail_installer/",
		unless  => "grep -qx exec_vnc_keepalived /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		require => [ File["/opt/contrail/contrail_installer/setup-vnc-keepalived.py"] ],
		logoutput => 'true'
	    }

->
	    setup-haproxy-config {'setup_haproxy_config':}

}



}

define setup-openstack-ha() {

#   if($contrail_openstack_ha == "yes") {
       package { 'contrail-openstack-ha' : ensure => present,}


 #  } 


}

define setup-cluster-monitor {
    notify { "cluser-monitor: internal_vip  is '$internal_vip' ":; }

	if ($internal_vip != '' and $internal_vip != 'none') {

		exec { "setup-cluster-monitor" :
		command => "service contrail-hamon restart && chkconfig contrail-hamon on  && echo setup-cluster-monitor >> /etc/contrail/contrail_openstack_exec.out ",
		require => [  ],
		unless  => "grep -qx setup-cluster-monitor  /etc/contrail/contrail_compute_exec.out",
		provider => shell,
		logoutput => "true"
	    }
	}
}

define fetch-ssl-certs($os_master, $os_username, $os_password)
{
	if ($internal_vip != '' and $internal_vip != 'none') {
		file { "/opt/contrail/contrail_installer/transfer_keys.py":
		   ensure  => present,
		   mode => 0755,
		   owner => root,
		   group => root,
		   source => "puppet:///modules/$module_name/transfer_keys.py"
		}
		exec { "exec-transfer-keys":
			command => "python /opt/contrail/contrail_installer/transfer_keys.py $os_master \"/etc/ssl/\" $os_username $os_password && echo exec-transfer-keys >> /etc/contrail/contrail_openstack_exec.out",
			provider => shell,
			logoutput => "true",
			unless  => "grep -qx exec-transfer-keys  /etc/contrail/contrail_oprenstack_exec.out",
			require => File["/opt/contrail/contrail_installer/transfer_keys.py"]
		}
	}
}

define mount-nfs($nfs_server, $glance_path) {
	if ($glance_path == "") {
		$nfs_glance_path = "/var/tmp/glance-images/" 

	} else {
		$nfs_glance_path = $glance_path 
	}
    exec { "mount-nfs" :
	command => "sudo mount $nfs_server:$glance_path /var/lib/glance/images &&( (grep \"$nfs_server:$glance_path /var/lib/glance/images nfs\" /etc/fstab) != 0 )&& echo \"$nfs_server:$glance_path /var/lib/glance/images nfs nfsvers=3,hard,intr,auto 0 0\" >> /etc/fstab && echo create-nfs >> /etc/contrail/contrail_openstack_exec.out ",
	require => [  ],
	unless  => "grep -qx create-nfs  /etc/contrail/contrail_oprenstack_exec.out",
	provider => shell,
	logoutput => "true"
    }

}

define fix-memcache-conf() {


    	file { "/opt/contrail/contrail_installer/fix-mem-cache.py":
       	   ensure  => present,
           mode => 0755,
           owner => root,
           group => root,
           source => "puppet:///modules/$module_name/fix-mem-cache.py"
        }
        exec { "exec-fix-memcache":
                command => "python /opt/contrail/contrail_installer/fix-mem-cache.py $self_ip && echo exec-fix-memcache >> /etc/contrail/contrail_openstack_exec.out",
                provider => shell,
                logoutput => "true",
		unless  => "grep -qx exec-fix-memcache  /etc/contrail/contrail_openstack_exec.out",
                require => File["/opt/contrail/contrail_installer/fix-mem-cache.py"]
        }

}

define fix-cmon-param-and-copy-ssh() {
        $compute_host_list_shell = inline_template('<%= compute_host_list.map{ |ip| "#{ip}" }.join(",") %>')
        $config_host_list_shell = inline_template('<%= config_host_list.map{ |ip| "#{ip}" }.join(",") %>')
    	file { "/opt/contrail/contrail_installer/fix-cmon-params-and-add-ssh-keys.py":
       	   ensure  => present,
           mode => 0755,
           owner => root,
           group => root,
           source => "puppet:///modules/$module_name/fix-cmon-params-and-add-ssh-keys.py"
        }
        exec { "exec-fix-cmon":
                command => "python /opt/contrail/contrail_installer/fix-cmon-params-and-add-ssh-keys.py $compute_host_list_shell $config_host_list_shell && echo exec-fix-cmon-add-params >> /etc/contrail/contrail_openstack_exec.out",
                provider => shell,
                logoutput => "true",
		unless  => "grep -qx exec-fix-cmon-add-params /etc/contrail/contrail_openstack_exec.out",
                require => File["/opt/contrail/contrail_installer/fix-cmon-params-and-add-ssh-keys.py"]
        }


}

define verify-openstack-status() {

	if ($internal_vip != '' and $internal_vip != 'none') {

		$openstack_ip_list_shell = inline_template('<%= openstack_ip_list.map{ |ip| "#{ip}" }.join(",") %>')
		$openstack_user_list_shell = inline_template('<%= openstack_user_list.map{ |ip| "#{ip}" }.join(",") %>')
		$openstack_password_list_shell = inline_template('<%= openstack_password_list.map{ |ip| "#{ip}" }.join(",") %>')

		file { "/opt/contrail/contrail_installer/verify_openstack_status.py":
		   ensure  => present,
		   mode => 0755,
		   owner => root,
		   group => root,
		   source => "puppet:///modules/$module_name/verify_openstack_status.py"
		}
		exec { "exec-verify-openstack-status":
			command => "python /opt/contrail/contrail_installer/verify_openstack_status.py $openstack_ip_list_shell $openstack_user_list_shell $openstack_password_list_shell && echo exec-verify-openstack-status >> /etc/contrail/contrail_openstack_exec.out",
			provider => shell,
			logoutput => "true",
			unless  => "grep -qx exec-verify-openstack-status  /etc/contrail/contrail_openstack_exec.out",
			require => File["/opt/contrail/contrail_installer/verify_openstack_status.py"]
		}
	}
}

# Following variables need to be set for this resource.
# Those specified with value assiged are optional, if not
# set the assigned value below is used.
#     $contrail_openstack_ip
#     $contrail_keystone_ip = $contrail_openstack_ip
#     $contrail_config_ip
#     $contrail_compute_ip
#     $contrail_openstack_mgmt_ip
#     $contrail_service_token
#     $contrail_ks_admin_passwd
#     $contrail_haproxy
#     $contrail_amqp_server_ip="127.0.0.1"
#     $contrail_ks_auth_protocol="http"
#     $contrail_quantum_service_protocol="http"
#     $contrail_ks_auth_port="35357"
define contrail_openstack (
        $contrail_keystone_ip = $contrail_openstack_ip,
        $contrail_amqp_server_ip= $contrail_amqp_server_ip,
        $contrail_ks_auth_protocol="http",
        $contrail_quantum_service_protocol="http",
        $contrail_ks_auth_port="35357"
    ) {

    $contrail_vm_ip = ""
    $contrail_vm_username = ""
    $contrail_vm_passwd = ""
    $contrail_vswitch = ""

    __$version__::contrail_common::report_status {"openstack_started": state => "openstack_started"}
    ->
    # list of packages
    package { 'contrail-openstack' : ensure => present,}

    #fix_rabbitmq_os{fix_rabbitmq_os:}

    setup-ha{setup_ha:
	internal_vip => $internal_vip
	}
/*
    setup-openstack-ha{setup_openstack_ha:
	ha => $ha
	}
    #get glance path from json
    $glance_path = "/var/lig/glance/images"

    mount-nfs {mount_nfs:
	nfs_server => $nfs_server,
	glance_path => $glance_path	
	}

*/
    # The above wrapper package should be broken down to the below packages
    # For Debian/Ubuntu - python-contrail, openstack-dashboard, contrail-openstack-dashboard, glance, keystone, nova-api, nova-common,
    #                     nova-conductor, nova-console, nova-objectstore, nova-scheduler, cinder-api, cinder-common, cinder-scheduler,
    #                     mysql-server, contrail-setup, memcached, nova-novncproxy, nova-consoleauth, python-m2crypto, haproxy,
    #                     rabbitmq-server, apache2, libapache2-mod-wsgi, python-memcache, python-iniparse, python-qpid, euca2ools
    # For Centos/Fedora - contrail-api-lib, openstack-dashboard, contrail-openstack-dashboard, openstack-glance, openstack-keystone,
    #                     openstack-nova, openstack-cinder, mysql-server, contrail-setup, memcached, openstack-nova-novncproxy,
    #                     python-glance, python-glanceclient, python-importlib, euca2ools, m2crypto, qpid-cpp-server,
    #                     haproxy, rabbitmq-server
/*
    setup-openstack-ha{setup_openstack_ha:`
		contrail_openstack_ha => $contrail_openstack_ha,
                after =>  package["contrail-openstack"],
		}
*/

#/*

    verify-openstack-status{verify_openstack_status: }
    setup-cluster-monitor{setup_cluster_monitor:
	
	}
     fetch-ssl-certs {fetch_ssl_certs:
	os_master => $os_master,
	os_username => $os_username,
	os_password => $os_password
	}
    openstack_hacks {openstack_hacks:}
#*/   
    if ($operatingsystem == "Centos" or $operatingsystem == "Fedora") {
        exec { "dashboard-local-settings-1" :
            command => "sudo sed -i 's/ALLOWED_HOSTS =/#ALLOWED_HOSTS =/g' /etc/openstack_dashboard/local_settings && echo dashboard-local-settings-1 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack_dashboard/local_settings",
            unless  => "grep -qx dashboard-local-settings-1 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }
        exec { "dashboard-local-settings-2" :
            command => "sudo sed -i 's/ALLOWED_HOSTS =/#ALLOWED_HOSTS =/g' /etc/openstack-dashboard/local_settings && echo dashboard-local-settings-2 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack-dashboard/local_settings",
            unless  => "grep -qx dashboard-local-settings-2 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }
    }

    if ($operatingsystem == "Ubuntu") {

        $line1="HORIZON_CONFIG[\'customization_module\']=\'contrail_openstack_dashboard.overrides\'"
        exec { "dashboard-local-settings-3" :
            command => "sudo sed -i '/HORIZON_CONFIG.*customization_module.*/d' /etc/openstack-dashboard/local_settings.py && echo \"$line1\"  >> /etc/openstack-dashboard/local_settings.py  && echo dashboard-local-settings-3 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack-dashboard/local_settings.py",
            unless  => "grep -qx dashboard-local-settings-3 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }

        $line2="LOGOUT_URL=\'/horizon/auth/logout/\'"
        exec { "dashboard-local-settings-4" :

            command => "sudo sed -i '/LOGOUT_URL.*/d' /etc/openstack-dashboard/local_settings.py && echo \"$line2\" >> /etc/openstack-dashboard/local_settings.py && service apache2 restart && echo dashboard-local-settings-4 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack-dashboard/local_settings.py",
            unless  => "grep -qx dashboard-local-settings-4 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }
    }
    if ($operatingsystem == "Centos") {
        exec { "dashboard-local-settings-3" :
            command => "sudo sed -i '/HORIZON_CONFIG.*customization_module.*/d' /etc/openstack-dashboard/local_settings && echo HORIZON_CONFIG['customization_module'] = 'contrail_openstack_dashboard.overrides' >> etc/openstack-dashboard/local_settings  && echo dashboard-local-settings-3 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack-dashboard/local_settings",
            unless  => "grep -qx dashboard-local-settings-3 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }

        exec { "dashboard-local-settings-4" :
            command => "sudo sed -i '/LOGOUT_URL.*/d' etc/openstack-dashboard/local_settings && echo LOGOUT_URL='/horizon/auth/logout/' >> etc/openstack-dashboard/local_settings && service httpd restart && echo dashboard-local-settings-4 >> /etc/contrail/contrail_openstack_exec.out",
            require =>  package["contrail-openstack"],
            onlyif => "test -f /etc/openstack-dashboard/local_settings",
            unless  => "grep -qx dashboard-local-settings-4 /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true'
        }
    }

    exec { "update-nova-conf-file" :
        command => "sudo sed -i 's/rpc_backend = nova.openstack.common.rpc.impl_qpid/#rpc_backend = nova.openstack.common.rpc.impl_qpid/g' /etc/nova/nova.conf && echo update-nova-conf-file >> /etc/contrail/contrail_openstack_exec.out",
        require =>  package["contrail-openstack"],
        onlyif => "test -f /etc/nova/nova.conf",
        unless  => "grep -qx update-nova-conf-file /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => 'true'
    }

    ##Chhandak Added this section to update nova.conf with corect rabit_host ip
    exec { "update-nova-conf-file1" :
        #command => "sudo sed -i 's/#rabbit_host\s*=\s*127.0.0.1/rabbit_host = $contrail_amqp_server_ip/g' /etc/nova/nova.conf && echo update-nova-conf-file1 >> /etc/contrail/contrail_openstack_exec.out",
        command => "openstack-config --set /etc/nova/nova.conf DEFAULT rabbit_host $contrail_amqp_server_ip && echo update-nova-conf-file1 >> /etc/contrail/contrail_openstack_exec.out",
        require =>  package["contrail-openstack"],
        onlyif => "test -f /etc/nova/nova.conf",
        unless  => "grep -qx update-nova-conf-file1 /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => 'true'
    }

    ##Chhandak Added this section to update nova.conf with corect rabit_host ip
    exec { "update-nova-conf-file2" :
        #command => "sudo sed -i 's/#rabbit_host\s*=\s*127.0.0.1/rabbit_host = $contrail_amqp_server_ip/g' /etc/nova/nova.conf && echo update-nova-conf-file1 >> /etc/contrail/contrail_openstack_exec.out",
        command => "openstack-config --set /etc/nova/nova.conf keystone_authtoken rabbit_host $contrail_amqp_server_ip  && echo update-nova-conf-file2 >> /etc/contrail/contrail_openstack_exec.out",
        require =>  package["contrail-openstack"],
        onlyif => "test -f /etc/nova/nova.conf",
        unless  => "grep -qx update-nova-conf-file2 /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => 'true'
    }

    exec { "update-cinder-conf-file" :
        command => "sudo sed -i 's/rpc_backend = cinder.openstack.common.rpc.impl_qpid/#rpc_backend = cinder.openstack.common.rpc.impl_qpid/g' /etc/cinder/cinder.conf && echo update-cinder-conf-file >> /etc/contrail/contrail_openstack_exec.out",
        require =>  package["contrail-openstack"],
        onlyif => "test -f /etc/cinder/cinder.conf",
        unless  => "grep -qx update-cinder-conf-file /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => 'true'
    }

    # Handle rabbitmq.conf changes
    #$conf_file = "/etc/rabbitmq/rabbitmq.config"
    #if ! defined(File["/etc/contrail/contrail_setup_utils/cfg-qpidd-rabbitmq.sh"]) {
    #    file { "/etc/contrail/contrail_setup_utils/cfg-qpidd-rabbitmq.sh" : 
    #        ensure  => present,
    #        mode => 0755,
    #        owner => root,
    #        group => root,
    #        source => "puppet:///modules/$module_name/cfg-qpidd-rabbitmq.sh"
    #    }
    #}
    #if ! defined(Exec["exec-cfg-qpidd-rabbitmq"]) {
    #    exec { "exec-cfg-qpidd-rabbitmq" :
    #        command => "/bin/bash /etc/contrail/contrail_setup_utils/cfg-qpidd-rabbitmq.sh $operatingsystem $conf_file && echo exec-cfg-qpidd-rabbitmq >> /etc/contrail/contrail_openstack_exec.out",
    #        require =>  File["/etc/contrail/contrail_setup_utils/cfg-qpidd-rabbitmq.sh"],
    #        unless  => "grep -qx exec-cfg-qpidd-rabbitmq /etc/contrail/contrail_openstack_exec.out",
    #        provider => shell,
    #        logoutput => 'true'
    #    }
    #}

    file { "/etc/contrail/contrail_setup_utils/api-paste.sh" : 
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
        source => "puppet:///modules/$module_name/api-paste.sh"
    }
    exec { "exec-api-paste" :
        command => "/bin/bash /etc/contrail/contrail_setup_utils/api-paste.sh && echo exec-api-paste >> /etc/contrail/contrail_openstack_exec.out",
        require =>  File["/etc/contrail/contrail_setup_utils/api-paste.sh"],
        unless  => "grep -qx exec-api-paste /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => 'true'
    }

    exec { "exec-openstack-qpid-rabbitmq-hostname" :
        command => "echo \"rabbit_host = $contrail_amqp_server_ip\" >> /etc/nova/nova.conf && echo exec-openstack-qpid-rabbitmq-hostname >> /etc/contrail/contrail_openstack_exec.out",
        require =>  Package["contrail-openstack"],
        unless  => ["grep -qx exec-openstack-qpid-rabbitmq-hostname /etc/contrail/contrail_openstack_exec.out",
                    "grep -qx \"rabbit_host = $contrail_amqp_server_ip\" /etc/nova/nova.conf"],
        provider => shell,
        logoutput => 'true'
    }
    
    # Ensure ctrl-details file is present with right content.
    if ! defined(File["/etc/contrail/ctrl-details"]) {
        $quantum_port = "9697"
        if $contrail_haproxy == "enable" {
		$quantum_ip = "127.0.0.1"
	} else {
		$quantum_ip = $contrail_config_ip
	}
        if ($internal_vip == undef) {
                $internal_vip = "none"
        }
        if ($external_vip == undef) {
                $external_vip = "none"
        }
       if ($contrail_internal_vip == undef) {
                $contrail_internal_vip = "none"
        }
       if ($contrail_external_vip == undef) {
                $contrail_external_vip = "none"
        }

        file { "/etc/contrail/ctrl-details" :
            ensure  => present,
            content => template("$module_name/ctrl-details.erb"),
        }

    }

    # Ensure service.token file is present with right content.
    if ! defined(File["/etc/contrail/service.token"]) {
        file { "/etc/contrail/service.token" :
            ensure  => present,
            content => template("$module_name/service.token.erb"),
        }
    }

    if ! defined(Exec["neutron-conf-exec"]) {
        exec { "neutron-conf-exec":
            command => "sudo sed -i 's/rpc_backend\s*=\s*neutron.openstack.common.rpc.impl_qpid/#rpc_backend = neutron.openstack.common.rpc.impl_qpid/g' /etc/neutron/neutron.conf && echo neutron-conf-exec >> /etc/contrail/contrail_openstack_exec.out",
            onlyif => "test -f /etc/neutron/neutron.conf",
            unless  => "grep -qx neutron-conf-exec /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => "true"
        }
    }

    if ! defined(Exec["quantum-conf-exec"]) {
        exec { "quantum-conf-exec":
            command => "sudo sed -i 's/rpc_backend\s*=\s*quantum.openstack.common.rpc.impl_qpid/#rpc_backend = quantum.openstack.common.rpc.impl_qpid/g' /etc/quantum/quantum.conf && echo quantum-conf-exec >> /etc/contrail/contrail_openstack_exec.out",
            onlyif => "test -f /etc/quantum/quantum.conf",
            unless  => "grep -qx quantum-conf-exec /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => "true"
        }
    }

    # Execute keystone-server-setup script
    openstack-scripts { ["keystone-server-setup", "glance-server-setup", "cinder-server-setup", "nova-server-setup"]: }


#    if (0)  {
#    	file { "/etc/haproxy/haproxy.cfg":
#       	   ensure  => present,
#           mode => 0755,
##           owner => root,
#           group => root,
#           source => "puppet:///modules/$module_name/$hostname.cfg"
#        }
#        exec { "haproxy-exec":
#                command => "sudo sed -i 's/ENABLED=.*/ENABLED=1/g' /etc/default/haproxy;",
#                provider => shell,
#                logoutput => "true",
#                require => File["/etc/haproxy/haproxy.cfg"]
#        }
#        service { "haproxy" :
#            enable => true,
#            require => [File["/etc/default/haproxy"],
#                        File["/etc/haproxy/haproxy.cfg"]],
#            ensure => running
#        }
#    }

    # repeat keystone setup (workaround for now) Needs to be fixed .. Abhay
    if ($operatingsystem == "Ubuntu") {
	    exec { "setup-keystone-server-2setup" :
		    command => "/opt/contrail/contrail_installer/contrail_setup_utils/keystone-server-setup.sh $operatingsystem && echo setup-keystone-server-2setup >> /etc/contrail/contrail_openstack_exec.out",
		    require => [ File["/opt/contrail/contrail_installer/contrail_setup_utils/keystone-server-setup.sh"],
		    File["/etc/contrail/ctrl-details"],
		    Openstack-scripts['nova-server-setup'] ],
		    unless  => "grep -qx setup-keystone-server-2setup /etc/contrail/contrail_openstack_exec.out",
		    provider => shell,
		    logoutput => "true",
		    before => Service['mysqld']
	    }
# Below is temporary to work-around in Ubuntu as Service resource fails
# as upstart is not correctly linked to /etc/init.d/service-name
	    file { '/etc/init.d/mysqld':
		    ensure => link,
			   target => '/lib/init/upstart-job',
			   before => Service["mysqld"]
	    }
	    file { '/etc/init.d/openstack-keystone':
		    ensure => link,
			   target => '/lib/init/upstart-job',
			   before => Service["openstack-keystone"]
	    }
    }
    ##Chhandak Added this section to update /etc/mysql/my.cnf to remove bind address
    exec { "update-mysql-file1" :
        command => "sudo sed -i -e 's/bind-address/#bind-address/g' /etc/mysql/my.cnf && echo update-mysql-file1 >> /etc/contrail/contrail_openstack_exec.out",
        require =>  package["contrail-openstack"],
        onlyif => "test -f /etc/mysql/my.cnf",
        unless  => "grep -qx update-mysql-file1 /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => 'true',
        before => Service["mysqld"]
    }

    exec { "restart-supervisor-openstack":
        command => "service supervisor-openstack restart && echo restart-supervisor-openstack >> /etc/contrail/contrail_openstack_exec.out",
        unless  => "grep -qx restart-supervisor-openstack /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => "true"
    }
    # Ensure the services needed are running.
    service { "mysqld" :
        enable => true,
        require => [ Package['contrail-openstack'] ],
        ensure => running,
    }

    service { "openstack-keystone" :
        enable => true,
        require => [ Package['contrail-openstack'],
                     Openstack-scripts["nova-server-setup"] ],
        ensure => running,
    }
    service { "memcached" :
        enable => true,
        ensure => running,
    }
    ->
    __$version__::contrail_common::report_status {"openstack_completed": state => "openstack_completed"}



    Package['contrail-openstack']->Setup-ha['setup_ha']->File['/etc/contrail/contrail_setup_utils/api-paste.sh']->Exec['exec-api-paste']->Exec['exec-openstack-qpid-rabbitmq-hostname']->File["/etc/contrail/ctrl-details"]->File["/etc/contrail/service.token"]->Openstack-scripts["keystone-server-setup"]->Openstack-scripts["glance-server-setup"]->Openstack-scripts["cinder-server-setup"]->Openstack-scripts["nova-server-setup"]->Exec['setup-keystone-server-2setup']->Service['openstack-keystone']->Service['mysqld']->Service['memcached']->Exec['neutron-conf-exec']->Exec['dashboard-local-settings-3']->Exec['dashboard-local-settings-4']->Exec['restart-supervisor-openstack']->Verify-openstack-status['verify_openstack_status']->Setup-cluster-monitor['setup_cluster_monitor']->Fetch-ssl-certs['fetch_ssl_certs']->Openstack_hacks['openstack_hacks']

}
# end of user defined type contrail_openstack.

}
