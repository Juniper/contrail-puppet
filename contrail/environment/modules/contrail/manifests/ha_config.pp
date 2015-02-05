# == Class: contrail::ha_config
#
# This class is used to configure software and services required
# to provide HA functionality of contrail/openstack cluster.
#
# === Parameters:
#
# [*host_control_ip*]
#     IP address of the server.
#     If server has separate interfaces for management and control, this
#     parameter should provide control interface IP address.
#
# [*openstack_ip_list*]
#     List of control IP addresses of all servers running openstack.
#     Current host also runs openstack. It's address it to be passed as
#     first element of the list.
#
# [*openstack_mgmt_ip_list*]
#     List of management IP addresses of all servers running openstack.
#     Current host also runs openstack. It's address it to be passed as
#     first element of the list.
#
# [*mysql_root_password*]
#     Mysql Root password of the server.
#
# [*internal_vip*]
#     Virtual IP of this server used for providing HA functinality.
#     (optional) - Defaults to "".
#
# [*keystone_admin_token*]
#     Keystone admin token.
#     (optional) - Defaults to "c0ntrail123".
#
# [*keystone_ip*]
#     Key stone IP address, if keystone service is running on a node other
#     than openstack controller.
#     (optional) - Default "", meaning use same address as openstack controller.
#
class contrail::ha_config (
    $host_control_ip = $::contrail::params::host_ip,
    $openstack_ip_list = $::contrail::params::openstack_ip_list,
    $compute_name_list = $::contrail::params::compute_name_list,
    $config_name_list = $::contrail::params::config_name_list,
    $compute_name_list = $::contrail::params::compute_name_list,
    $openstack_mgmt_ip_list = $::contrail::params::openstack_mgmt_ip_list_to_use,
    $mysql_root_password = $::contrail::params::mysql_root_password,
    $internal_vip = $::contrail::params::internal_vip,
    $keystone_admin_token = $::contrail::params::keystone_admin_token,
    $openstack_passwd_list = $::contrail::params::openstack_passwd_list,
    $config_passwd_list = $::contrail::params::config_passwd_list,
    $compute_passwd_list = $::contrail::params::compute_passwd_list,
    $openstack_user_list = $::contrail::params::openstack_user_list,
    $keystone_ip = $::contrail::params::keystone_ip,
    $nfs_server = $::contrail::params::nfs_server,
    $nfs_glance_path = $::contrail::params::nfs_glance_path,
) inherits ::contrail::params {
    # Main code for class
    if($internal_vip != '' and $host_control_ip in $openstack_ip_list) {
        if ($operatingsystem == "Ubuntu") {
            $wsrep_conf='/etc/mysql/conf.d/wsrep.cnf'
        } else {
            $wsrep_conf='/etc/mysql/my.cnf'
        }

        if ($keystone_ip != "") {
            $keystone_ip_to_use = $keystone_ip
        }
        else {
            $keystone_ip_to_use = $internal_vip
        }

        $tmp_index = inline_template('<%= @openstack_mgmt_ip_list.index(@host_control_ip) %>')
        if ($tmp_index != nil) {
            $openstack_index = $tmp_index + 1
        }
        $os_master = $openstack_ip_list[0]
        $os_username = $openstack_user_list[0]
	$os_passwd = $openstack_passwd_list[0]

        if ($nfs_server != "" and nfs_server != undef) {

	   $contrail_nfs_server = $nfs_server

        } else {
	   $contrail_nfs_server = $openstack_ip_list[0]
        }

        if ($nfs_glance_path != "" and nfs_glance_path != undef) {

	   $contrail_nfs_glance_path = $nfs_glance_path

        } else {
	   $contrail_nfs_glance_path = "/var/lib/glance/images"
        }

      

        $openstack_mgmt_ip_list_shell = inline_template('<%= @openstack_mgmt_ip_list.map{ |ip| "#{ip}" }.join(",") %>')
        $openstack_ip_list_shell = inline_template('<%= @openstack_ip_list.map{ |name2| "#{name2}" }.join(" ") %>')

        $config_name_list_shell = inline_template('<%= @config_name_list.map{ |name2| "#{name2}" }.join(",") %>')
        $compute_name_list_shell = inline_template('<%= @compute_name_list.map{ |name2| "#{name2}" }.join(",") %>')


        $openstack_user_list_shell = inline_template('<%= openstack_user_list.map{ |ip| "#{ip}" }.join(",") %>')
        $openstack_passwd_list_shell = inline_template('<%= openstack_passwd_list.map{ |ip| "#{ip}" }.join(",") %>')

	$openstack_ip_list_wsrep = inline_template('<%= @openstack_mgmt_ip_list.map{ |ip| "#{ip}:4567" }.join(",") %>')

        $contrail_exec_vnc_galera = "MYSQL_ROOT_PW=$mysql_root_password ADMIN_TOKEN=$keystone_admin_token setup-vnc-galera --self_ip $host_control_ip --keystone_ip $keystone_ip_to_use --galera_ip_list $openstack_ip_list_shell --internal_vip $internal_vip --openstack_index $openstack_index && echo exec_vnc_galera >> /etc/contrail/contrail_openstack_exec.out"
        $contrail_exec_check_wsrep = "python check-wsrep-status.py $openstack_mgmt_ip_list_shell  && echo check-wsrep >> /etc/contrail/contrail_openstack_exec.out"
        $contrail_exec_setup_cmon_schema = "python setup-cmon-schema.py $os_master $host_control_ip $internal_vip $openstack_mgmt_ip_list_shell && echo exec_setup_cmon_schema >> /etc/contrail/contrail_openstack_exec.out"

        $contrail_exec_password_less_ssh = "python /opt/contrail/bin/setup_passwordless_ssh.py $openstack_mgmt_ip_list_shell $openstack_user_list_shell $openstack_passwd_list_shell && echo exec-setup-password-less-ssh >> /etc/contrail/contrail_openstack_exec.out"
        #########Chhandak-HA
        # GALERA
        package { 'contrail-openstack-ha':
            ensure  => present,
        }
        ->
        file { "/etc/contrail/mysql.token" :
            ensure  => present,
            mode =>    0400,
            group => root,
            content => "$mysql_root_password"
        }

        file { "/opt/contrail/bin/setup_passwordless_ssh.py" :
            ensure  => present,
            mode => 0755,
            group => root,
            source => "puppet:///modules/$module_name/setup_passwordless_ssh.py"
        }
        ->
	exec { "exec_password_less_ssh" :
	    command => $contrail_exec_password_less_ssh,
	    cwd => "/opt/contrail/bin/",
	    unless  => "grep -qx exec-setup-password-less-ssh /etc/contrail/contrail_openstack_exec.out",
	    provider => shell,
	    require => [ File["/opt/contrail/bin/setup_passwordless_ssh.py"] ],
	    logoutput => 'true'
	}

        ->
        file { "/opt/contrail/bin/setup-vnc-galera" :
            ensure  => present,
            mode =>    0755,
            group => root,
        }
        ->
        exec { "exec_vnc_galera" :
            command => $contrail_exec_vnc_galera,
            cwd => "/opt/contrail/bin/",
            unless  => "grep -qx exec_vnc_galera /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            require => [ File["/opt/contrail/bin/setup-vnc-galera"] ],
            logoutput => 'true',
            tries => 3,
            try_sleep => 15,
        }
        if ($openstack_index == "1" ) {
            # Fix WSREP cluster address
            # Need check this from provisioned ha box


	    file { "/opt/contrail/bin/check_galera.py" :
		ensure  => present,
		mode => 0755,
		group => root,
		source => "puppet:///modules/$module_name/check_galera.py"
	    }
	    ->
	    exec { "exec_check_galera" :
		command => "python /opt/contrail/bin/check_galera.py $openstack_mgmt_ip_list_shell $openstack_user_list_shell $openstack_passwd_list_shell && echo check_galera >> /etc/contrail/contrail_openstack_exec.out",
		cwd => "/opt/contrail/bin/",
		unless  => "grep -qx check_galera /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		require => [ File["/opt/contrail/bin/check_galera.py"] ],
		logoutput => 'true',
	    }
            ->
	    file { "/opt/contrail/bin/check-wsrep-status.py" :
		ensure  => present,
		mode => 0755,
		group => root,
		source => "puppet:///modules/$module_name/check-wsrep-status.py"
	    }
	    ->
	    exec { "exec_check_wsrep" :
		command => $contrail_exec_check_wsrep,  
		cwd => "/opt/contrail/bin/",
		unless  => "grep -qx exec_check_wsrep /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		require => [ File["/opt/contrail/bin/check-wsrep-status.py"] ],
		logoutput => 'true',
	    }

	    ->
            exec { "fix_wsrep_cluster_address" :
                command => "sudo sed -ibak 's#wsrep_cluster_address=.*#wsrep_cluster_address=gcomm://$openstack_ip_list_wsrep#g' $wsrep_conf && service mysql restart && echo exec_fix_wsrep_cluster_address >> /etc/contrail/contrail_openstack_exec.out",
                require =>  [package["contrail-openstack-ha"],
                             Exec['exec_vnc_galera']],
                onlyif => "test -f $wsrep_conf",
                unless  => "grep -qx exec_fix_wsrep_cluster_address /etc/contrail/contrail_openstack_exec.out",
                provider => shell,
                logoutput => 'true',
            }
            ->
            exec { "ha-mon-restart":
                command => "service contrail-hamon restart && echo contrail-ha-mon >> /etc/contrail/contrail_openstack_exec.out",
                provider => shell,
                logoutput => "true",
                unless  => "grep -qx contrail-ha-mon  /etc/contrail/contrail_openstack_exec.out",
        #                require => File["/opt/contrail/bin/transfer_keys.py"]
            }



        }
        #This will be skipped if there is an external nfs server
        if ($contrail_nfs_server == $host_control_ip) {
	    package { 'nfs-kernel-server':
		ensure  => present,
	    }
            ->
            exec { "create-nfs" :
                command => "echo \"/var/lib/glance/images *(rw,sync,no_subtree_check)\" >> /etc/exports && sudo /etc/init.d/nfs-kernel-server restart && chown root:root /var/lib/glance/images && chmod 777 /var/lib/glance/images && echo create-nfs >> /etc/contrail/contrail_compute_exec.out ",
                require => [  ],
                unless  => "grep -qx create-nfs  /etc/contrail/contrail_compute_exec.out",
                provider => shell,
                logoutput => "true"
            }

        }

        # setup_cmon
        file { "/opt/contrail/bin/setup-cmon-schema.py" :
            ensure  => present,
            mode => 0755,
            group => root,
            source => "puppet:///modules/$module_name/setup-cmon-schema.py"
        }
        ->
        exec { "exec_setup_cmon_schema" :
            command => $contrail_exec_setup_cmon_schema,
            cwd => "/opt/contrail/bin/",
            unless  => "grep -qx exec_setup_cmon_schema /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            require => [ File["/opt/contrail/bin/setup-cmon-schema.py"] ],
            logoutput => 'true',
        }
/*
        ->
        exec { "setup-cluster-monitor" :
            command => "service contrail-hamon restart && chkconfig contrail-hamon on  && echo setup-cluster-monitor >> /etc/contrail/contrail_openstack_exec.out ",
            unless  => "grep -qx setup-cluster-monitor  /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => "true",
            tries => 3,
            try_sleep => 15,
        }
*/
        ->
        exec { "fix_xinetd_conf" :
            command => "sed -i -e 's#only_from = 0.0.0.0/0#only_from = $host_control_ip 127.0.0.1#' /etc/xinetd.d/contrail-mysqlprobe && service xinetd restart && chkconfig xinetd on && echo fix_xinetd_conf >> /etc/contrail/contrail_openstack_exec.out",
            unless  => "grep -qx fix_xinetd_conf  /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true',
        }
        # fix- mem-cache conf
        file { "/opt/contrail/bin/fix-mem-cache.py" :
            ensure  => present,
            mode => 0755,
            group => root,
            source => "puppet:///modules/$module_name/fix-mem-cache.py"
        }
        ->
        exec { "fix-mem-cache" :
            command => "python fix-mem-cache.py $host_control_ip && echo fix-mem-cache >> /etc/contrail/contrail_openstack_exec.out",
            cwd => "/opt/contrail/bin/",
            unless  => "grep -qx fix-mem-cache /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            require => [ File["/opt/contrail/bin/fix-mem-cache.py"] ],
            logoutput => 'true',
        }
        #TODO tune tcp
        #fix cmon and add ssh keys
         file { "/opt/contrail/bin/fix-cmon-params-and-add-ssh-keys.py" :
            ensure  => present,
            mode => 0755,
            group => root,
            source => "puppet:///modules/$module_name/fix-cmon-params-and-add-ssh-keys.py"
        }
        ->
        exec { "fix-cmon-params-and-add-ssh-keys" :
            command => "python fix-cmon-params-and-add-ssh-keys.py $compute_name_list_shell $config_name_list_shell && echo fix-cmon-params-and-add-ssh-keys >> /etc/contrail/contrail_openstack_exec.out",
            cwd => "/opt/contrail/bin/",
            unless  => "grep -qx fix-cmon-params-and-add-ssh-keys /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            require => [ File["/opt/contrail/bin/fix-cmon-params-and-add-ssh-keys.py"], Exec["exec_vnc_galera"] ],
            logoutput => 'true',
        }
        ->
        file { "/opt/contrail/bin/transfer_keys.py":
           ensure  => present,
           mode => 0755,
           owner => root,
           group => root,
           source => "puppet:///modules/$module_name/transfer_keys.py"
        }
        ->
        exec { "exec-transfer-keys":
                command => "python /opt/contrail/bin/transfer_keys.py $os_master \"/etc/ssl/\" $os_username $os_passwd && echo exec-transfer-keys >> /etc/contrail/contrail_openstack_exec.out",
                provider => shell,
                logoutput => "true",
                unless  => "grep -qx exec-transfer-keys  /etc/contrail/contrail_openstack_exec.out",
                require => File["/opt/contrail/bin/transfer_keys.py"]
        }
        #This wil be executed for all openstacks ,if there is an external nfs server
        if ($contrail_nfs_server != $host_control_ip ) {
	    package { 'nfs-common':
		ensure  => present,
	    }
            ->
	    exec { "mount-nfs" :
		command => "sudo mount $contrail_nfs_server:$contrail_nfs_glance_path /var/lib/glance/images && echo mount-nfs >> /etc/contrail/contrail_openstack_exec.out",
		require => [  ],
		unless  => "grep -qx mount-nfs  /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		logoutput => "true"
	    }
	    exec { "add-fstab" :
		command => "echo \"$contrail_nfs_server:$contrail_nfs_glance_path /var/lib/glance/images nfs nfsvers=3,hard,intr,auto 0 0\" >> /etc/fstab && echo add-fstab >> /etc/contrail/contrail_openstack_exec.out ",
		unless  => "grep -qx add-fstab  /etc/contrail/contrail_openstack_exec.out",
		provider => shell,
		logoutput => "true"
	    }

        }

    }
}
