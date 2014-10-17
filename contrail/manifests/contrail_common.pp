class __$version__::contrail_common {

# Macro to ensure that a line is either presnt or absent in file.
define line($file, $line, $ensure = 'present') {
    case $ensure {
        default : { err ( "unknown ensure value ${ensure}" ) }
        present: {
            exec { "/bin/echo '${line}' >> '${file}'":
                unless => "/bin/grep -qFx '${line}' '${file}'",
                logoutput => "true"
            }
        }
        absent: {
            exec { "/bin/grep -vFx '${line}' '${file}' | /usr/bin/tee '${file}' > /dev/null 2>&1":
              onlyif => "/bin/grep -qFx '${line}' '${file}'",
                logoutput => "true"
            }

            # Use this resource instead if your platform's grep doesn't support -vFx;
            # note that this command has been known to have problems with lines containing quotes.
            # exec { "/usr/bin/perl -ni -e 'print unless /^\\Q${line}\\E\$/' '${file}'":
            #     onlyif => "/bin/grep -qFx '${line}' '${file}'",
            #     logoutput => "true"
            # }
        }
    }
}
# End of macro line

define upgrade-kernel($contrail_kernel_version) {
    $headers = "linux-headers-${contrail_kernel_version}"
    $headers_generic = "linux-headers-${contrail_kernel_version}-generic"
    $image = "linux-image-${contrail_kernel_version}"
    package { 'apparmor' : ensure => '2.7.102-0ubuntu3.10',}
    ->
    package { $headers : ensure => present, }
    ->
    package { $headers_generic : ensure => present, }
    ->
    package { $image : ensure => present, }
    ->
    exec { "upgrade-kernel-reboot":
        command => "echo upgrade-kernel-reboot >> /etc/contrail/contrail_common_exec.out && reboot ",
        provider => shell,
        logoutput => "true",
	unless => ["grep -qx upgrade-kernel-reboot /etc/contrail/contrail_common_exec.out"]
    }
}

#end of upgrade-kernel

#source ha proxy files
define haproxy-cfg($server_id) {
    file { "/etc/haproxy/haproxy.cfg":
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
        source => "puppet:///modules/$module_name/$server_id.cfg"
    }
    exec { "haproxy-exec":
        command => "sed -i 's/ENABLED=.*/ENABLED=1/g' /etc/default/haproxy",
        provider => shell,
        logoutput => "true",
        require => File["/etc/haproxy/haproxy.cfg"]
    }
    service { "haproxy" :
        enable => true,
        require => [File["/etc/default/haproxy"],
                    File["/etc/haproxy/haproxy.cfg"]],
        ensure => running
        }
}

# Following variables need to be set for this resource.
#     $zk_ip_list
#     $zk_index
define contrail-cfg-zk() {
    package { 'zookeeper' : ensure => present,}
    package { 'zookeeperd' : ensure => present,}

     # set high session timeout to survive glance led disk activity
    file { "/etc/contrail/contrail_setup_utils/config-zk-files-setup.sh":
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
	require => [ Package['zookeeper'],
                     Package['zookeeperd'] ],
        source => "puppet:///modules/$module_name/config-zk-files-setup.sh"
    }

    $contrail_zk_ip_list_for_shell = inline_template('<%= zk_ip_list.map{ |ip| "#{ip}" }.join(" ") %>')

    exec { "setup-config-zk-files-setup" :
        command => "/bin/bash /etc/contrail/contrail_setup_utils/config-zk-files-setup.sh $operatingsystem $zk_index $contrail_zk_ip_list_for_shell && echo setup-config-zk-files-setup >> /etc/contrail/contrail_config_exec.out",
        require => File["/etc/contrail/contrail_setup_utils/config-zk-files-setup.sh"],
        unless  => "grep -qx setup-config-zk-files-setup /etc/contrail/contrail_config_exec.out",
        provider => shell,
        logoutput => "true"
    }
}

#source ha proxy files
define contrail-exec-script($script_name, $args) {
    file { "/etc/contrail/${script_name}":
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
        source => "puppet:///modules/$module_name/$script_name"
    }
    exec { "script-exec":
        command => "/etc/contrail/${script_name} $args; echo script-exec${script_name} >> /etc/contrail/contrail_common_exec.out",
        provider => shell,
        logoutput => "true",
        unless  => "grep -qx script-exec${script_name} /etc/contrail/contrail_common_exec.out",
        require => File["/etc/contrail/${script_name}"]
    }
}

define create-interface-cb(
	$contrail_package_id
) {
    exec { "contrail-interface-cb" :
        command => "curl -H \"Content-Type: application/json\" -d '{\"package_image_id\":\"$contrail_package_id\",\"id\":\"$hostname\"}' http://$serverip:9001/interface_created && echo create-interface-cb >> /etc/contrail/contrail_common_exec.out",
        provider => shell,
        logoutput => "true"
    }
}

define contrail-setup-interface(
        $contrail_device,
        $contrail_members,
        $contrail_bond_opts,
        $contrail_ip,
        $contrail_gw
    ) {


#	notify { "member are  $contrail_members":; }  

     	# Setup contrail-install-packages
    	package {'ifenslave': ensure => present}
        package {'contrail-setup': ensure => present} 

#	$contrail_member_list = inline_template('<%= contrail_members.delete! "" %>')
	$contrail_member_list = $contrail_members
        $contrail_intf_member_list_for_shell = inline_template('<%= contrail_member_list.map{ |ip| "#{ip}" }.join(" ") %>')


	if($contrail_members == "" ) {

	    $exec_cmd = "/opt/contrail/bin/setup-vnc-interfaces --device $contrail_device --ip $contrail_ip"
	} else {
	    $exec_cmd = "/opt/contrail/bin/setup-vnc-interfaces --device $contrail_device --members $contrail_intf_member_list_for_shell --bond-opts \"$contrail_bond_opts\" --ip $contrail_ip"
	}

	if ($contrail_gw != "" ) {
	    $gw_suffix = " --gw $contrail_gw && echo setup-intf${contrail_device} >> /etc/contrail/contrail_common_exec.out"
	    $exec_full_cmd = "${exec_cmd}${gw_suffix}"
 	} else 	{
	    $gw_suffix =  " && echo setup-intf${contrail_device} >> /etc/contrail/contrail_common_exec.out"
	    $exec_full_cmd = "${exec_cmd}${gw_suffix}"
	}

	notify { "command executed is $exec_full_cmd":; }  
        
	exec { "setup-intf-$contrail_device":
            command => $exec_full_cmd,
            provider => shell,
            logoutput => "true",
	    require=> [Package["ifenslave"], Package["contrail-setup"]],
            unless  => "grep -qx setup-intf${contrail_device} /etc/contrail/contrail_common_exec.out"
        }
}

define contrail-setup-repo(
        $contrail_repo_name,
        $contrail_server_mgr_ip
    ) {
    if ($operatingsystem == "Centos" or $operatingsystem == "Fedora") {
        file { "/etc/yum.repos.d/cobbler-config.repo" :
            ensure  => present,
            content => template("$module_name/contrail-yum-repo.erb")
        }
    }
    if ($operatingsystem == "Ubuntu") {
        $pattern1 = "deb http:\/\/$contrail_server_mgr_ip\/contrail\/repo\/$contrail_repo_name .\/"
        $pattern2 = "deb http://$contrail_server_mgr_ip/contrail/repo/$contrail_repo_name ./"
        $repo_cfg_file = "/etc/apt/sources.list"
        exec { "update-sources-list-$contrail_repo_name" :
            command   => "sed -i \"/$pattern1/d\" $repo_cfg_file && echo \"$pattern2\"|cat - $repo_cfg_file > /tmp/out && mv /tmp/out $repo_cfg_file && apt-get update",
            unless  => "head -1 $repo_cfg_file | grep -qx \"$pattern2\"",
            provider => shell,
            logoutput => "true"
        }
    }
}

define contrail-install-repo(
	$contrail_repo_type
	) {

    if($contrail_repo_type == "contrail-ubuntu-package") {
        $setup_script =  "./setup.sh && echo exec-contrail-setup-$contrail_repo_type-sh >> exec-contrail-setup-sh.out"
        $package_name = "contrail-install-packages"
    } elsif ($contrail_repo_type == "contrail-centos-package") {
        $setup_script =  "./setup.sh && echo exec-contrail-setup-$contrail_repo_type-sh >> exec-contrail-setup-sh.out"
        $package_name = "contrail-install-packages"
    } elsif ($contrail_repo_type == "contrail-ubuntu-stroage-repo") {
        $setup_script =  "./setup_storage.sh && echo exec-contrail-setup-$contrail_repo_type-sh >> exec-contrail-setup-sh.out"
        $package_name = "contrail-storage"
    }

    package {$package_name: ensure => present}

    exec { "exec-contrail-setup-$contrail_repo_type-sh" :
        command => $setup_script,
        cwd => "/opt/contrail/contrail_packages",
        require => Package[$package_name],
        unless  => "grep -qx exec-contrail-setup-$contrail_repo_type-sh /opt/contrail/contrail_packages/exec-contrail-setup-sh.out",
        provider => shell,
        logoutput => "true"
    }
}

define report_status($state) {
/*
    if ! defined(Package['curl']) {
            package { 'curl' : ensure => present,}
    }

	}
    exec { "contrail-status-$state" :
        command => "mkdir -p /etc/contrail/ && curl -X PUT \"http://$serverip:9002/server_status?server_id=$hostname&state=$state\" && echo contrail-status-$state >> /etc/contrail/contrail_common_exec.out",
        provider => shell,
	require => Package["curl"],
        unless  => "grep -qx contrail-status-$state /etc/contrail/contrail_common_exec.out",
        logoutput => "true"
    }
*/

}
define contrail_setup_gid($group_gid ) {
  notify { "Group ${name} to be created with ${group_gid}": }
  exec {"create-group-${name}" :
    command => "groupadd  -g $group_gid $name",
    unless => "getent group $name | grep -q $group_gid",
    provider  => shell,
    logoutput => "true",
   #require => contrail_setup_gid["$user_group_name"]
  }
}

define contrail_setup_uid($user_uid, $user_group_name, $user_home_dir) {
  notify { "User ${name} to be created with ${user_uid} and ${user_group_name}":
    require => Contrail_setup_gid["$user_group_name"]
  }
  
  exec {"create-user-${name}" :
    command => "useradd -d $user_home_dir -g $user_group_name -r -s /bin/false -u $user_uid $name",
    unless => "id -u $name | grep -q $user_uid",
    provider  => shell,
    logoutput => "true",
    require => Contrail_setup_gid["$user_group_name"]
  }
}

define contrail_setup_users_groups() {
    if ($operatingsystem == "Ubuntu") {

	    $contrail_groups_details = {
	      'nova' 		=> { group_gid => '499' },
	      'libvirtd' 	=> { group_gid => '498' },
	      'kvm' 		=> { group_gid => '497' },
	    }
	    
	    $contrail_users_details = {
	      'nova' 		=> { user_uid => '499', user_group_name => 'nova', user_home_dir => '/var/lib/nova' },
	      'libvirt-qemu'	=> { user_uid => '498', user_group_name => 'kvm' , user_home_dir => '/var/lib/libvirt'},
	      'libvirt-dnsmasq' 	=> { user_uid => '497', user_group_name => 'libvirtd' , user_home_dir => '/var/lib/libvirt/dnsmasq'},
	    }
	    create_resources(__$VERSION__::Contrail_common::Contrail_setup_uid, $contrail_users_details, {})
	    create_resources(__$VERSION__::Contrail_common::Contrail_setup_gid, $contrail_groups_details, {})
    }
}

# macro to perform common functions
# Following variables need to be set for this resource.
#     $self_ip
#     $system_name
define contrail_common (
    ) {

    # Ensure /etc/hosts has an entry for self to map dns name to ip address
    host { "$system_name" :
        ensure => present,
        ip => "$self_ip"
    }

    # Disable SELINUX on boot, if not already disabled.
    if ($operatingsystem == "Centos" or $operatingsystem == "Fedora") {
        exec { "selinux-dis-1" :
            command   => "sed -i \'s/SELINUX=.*/SELINUX=disabled/g\' config",
            cwd       => '/etc/selinux',
            onlyif    => '[ -d /etc/selinux ]',
            unless    => "grep -qFx 'SELINUX=disabled' '/etc/selinux/config'",
            provider  => shell,
            logoutput => "true"
        }

        # disable selinux runtime
        exec { "selinux-dis-2" :
            command   => "setenforce 0 || true",
            unless    => "getenforce | grep -qi disabled",
            provider  => shell,
            logoutput => "true"
        }

        # Disable iptables
        service { "iptables" :
            enable => false,
            ensure => stopped
        }
    }

    if ($operatingsystem == "Ubuntu") {
        # disable firewall
        exec { "disable-ufw" :
            command   => "ufw disable",
            unless    => "ufw status | grep -qi inactive",
            provider  => shell,
            logoutput => "true"
        }
        # Create symbolic link to chkconfig. This does not exist on Ubuntu.
        file { '/sbin/chkconfig':
            ensure => link,
            target => '/bin/true'
        }
    }

    # Flush ip tables.
    exec { 'iptables --flush': provider => shell, logoutput => true }

    # Remove any core limit configured
    if ($operatingsystem == "Centos" or $operatingsystem == "Fedora") {
        exec { 'daemon-core-file-unlimited':
            command   => "sed -i \'/DAEMON_COREFILE_LIMIT=.*/d\' /etc/sysconfig/init; echo DAEMON_COREFILE_LIMIT=\"\'unlimited\'\" >> /etc/sysconfig/init",
            unless    => "grep -qx \"DAEMON_COREFILE_LIMIT='unlimited'\" /etc/sysconfig/init",
            provider => shell,
            logoutput => "true"
        }
    }
    if ($operatingsystem == "Ubuntu") {
        exec { "core-file-unlimited" :
            command   => "ulimit -c unlimited",
            unless    => "ulimit -c | grep -qi unlimited",
            provider  => shell,
            logoutput => "true"
        }
    }

    # Core pattern
    exec { 'core_pattern_1':
        command   => 'echo \'kernel.core_pattern = /var/crashes/core.%e.%p.%h.%t\' >> /etc/sysctl.conf',
        unless    => "grep -q 'kernel.core_pattern = /var/crashes/core.%e.%p.%h.%t' /etc/sysctl.conf",
        provider => shell,
        logoutput => "true"
    }

    # Enable ip forwarding in sysctl.conf for vgw
    exec { 'enable-ipf-for-vgw':
        command   => "sed -i \"s/net.ipv4.ip_forward.*/net.ipv4.ip_forward = 1/g\" /etc/sysctl.conf",
        unless    => ["[ ! -f /etc/sysctl.conf ]",
                      "grep -qx \"net.ipv4.ip_forward = 1\" /etc/sysctl.conf"],
        provider => shell,
        logoutput => "true"
    }

    # 
    exec { 'sysctl -e -p' : provider => shell, logoutput => on_failure }
    file { "/var/crashes":
        ensure => "directory",
    }

    # Make sure our scripts directory is present
    file { "/etc/contrail":
        ensure => "directory",
    }
    file { "/etc/contrail/contrail_setup_utils":
        ensure => "directory",
        require => File["/etc/contrail"]
    }

    # Enable kernel core.
    file { "/etc/contrail/contrail_setup_utils/enable_kernel_core.py":
        ensure  => present,
        mode => 0755,
        owner => root,
        group => root,
        source => "puppet:///modules/$module_name/enable_kernel_core.py"
    }

    # enable kernel core , below python code has bug, for now ignore by executing echo regardless and thus returning true for cmd.
    # need to revisit afterwards.
    exec { "enable-kernel-core" :
        #command => "python /etc/contrail/contrail_setup_utils/enable_kernel_core.py && echo enable-kernel-core >> /etc/contrail/contrail_common_exec.out",
        command => "python /etc/contrail/contrail_setup_utils/enable_kernel_core.py; echo enable-kernel-core >> /etc/contrail/contrail_common_exec.out",
        require => File["/etc/contrail/contrail_setup_utils/enable_kernel_core.py" ],
        unless  => "grep -qx enable-kernel-core /etc/contrail/contrail_common_exec.out",
        provider => shell,
        logoutput => "true"
    }

    # Why is this here ?? - Abhay
    if ($operatingsystem == "Ubuntu"){

        exec { "exec-update-neutron-conf" :
            command => "sed -i \"s/^rpc_backend = nova.openstack.common.rpc.impl_qpid/#rpc_backend = nova.openstack.common.rpc.impl_qpid/g\" /etc/neutron/neutron.conf && echo exec-update-neutron-conf >> /etc/contrail/contrail_common_exec.out",
            unless  => ["[ ! -f /etc/neutron/neutron.conf ]",
                        "grep -qx exec-update-neutron-conf /etc/contrail/contrail_common_exec.out"],
            provider => shell,
            logoutput => "true"
        }
    }

    # Why is this here ?? - Abhay
    if ($operatingsystem == "Centos" or $operatingsystem == "Fedora") {

        exec { "exec-update-quantum-conf" :
            command => "sed -i \"s/rpc_backend\s*=\s*quantum.openstack.common.rpc.impl_qpid/#rpc_backend = quantum.openstack.common.rpc.impl_qpid/g\" /etc/quantum/quantum.conf && echo exec-update-quantum-conf >> /etc/contrail/contrail_common_exec.out",
            unless  => ["[ ! -f /etc/quantum/quantum.conf ]",
                        "grep -qx exec-update-quantum-conf /etc/contrail/contrail_common_exec.out"],
            provider => shell,
            logoutput => "true"
        }
    

    }

    exec { "contrail-status" :
        command => "(contrail-status > /tmp/contrail_status || echo re-images > /tmp/contrail_status) &&  curl -v -X PUT -d @/tmp/contrail_status http://$serverip:9001/status?server_id=$hostname && echo contrail-status >> /etc/contrail/contrail_common_exec.out",
        provider => shell,
        logoutput => "true"
    }


}

}
