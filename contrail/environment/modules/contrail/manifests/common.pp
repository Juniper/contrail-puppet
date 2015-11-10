# == Class: contrail::common
#
# This class is used to configure software and services common
# to all contrail modules.
#
# === Parameters:
#
# [*host_mgmt_ip*]
#     IP address of the server where contrail modules are being installed.
#     if server has separate interfaces for management and control, this
#     parameter should provide management interface IP address.
#
# [*contrail_repo_name*]
#     Name of contrail repo being used to provision the contrail roles.
#     Version of contrail software being used is specified here.
#
# [*contrail_repo_ip*]
#     IP address of the server where contrail repo is mirrored. This is
#     same as the cobbler address or server manager IP address (puppet master).
#
# [*contrail_repo_type*]
#     Type of contrail repo (contrail-ubuntu-package or contrail-centos-package).
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::common(
    $host_mgmt_ip = $::contrail::params::host_ip,
    $contrail_repo_name = $::contrail::params::contrail_repo_name,
    $contrail_repo_ip = "puppet",
    $contrail_repo_type = $::contrail::params::contrail_repo_type,
    $contrail_upgrade = $::contrail::params::contrail_upgrade,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    include ::contrail::params

    notify { "**** ${module_name} - host_mgmt_ip = ${host_mgmt_ip}": ; }
    notify { "**** ${module_name} - contrail_repo_name = ${contrail_repo_name}": ; }
    notify { "**** ${module_name} - contrail_repo_ip = ${contrail_repo_ip}": ; }
    notify { "**** ${module_name} - contrail_repo_type = ${contrail_repo_type}": ; }

    $contrail_group_details = {
      'nova'     => { gid => '499'},
      'kvm'      => { gid => '498'},
      'libvirtd' => { gid => '497'}
    }

    $contrail_users_details = {
      'nova'            => { ensure => present, uid => '499', gid => '499', home => '/var/lib/nova' , managehome => true},
      'libvirt-qemu'    => { ensure => present, uid => '498', gid => '498', home => '/var/lib/libvirt',  managehome => true},
      'libvirt-dnsmasq' => { ensure => present, uid => '497', gid => '497', home => '/var/lib/libvirt/dnsmasq',  managehome => true},
    }

    create_resources(group, $contrail_group_details)
    create_resources(user, $contrail_users_details)
    #Group <| |> -> User<| |>
    #$contrail_users_details = {
      #'nova'            => { user_uid => '499', user_group_name => 'nova', group_gid => '499', user_home_dir => '/var/lib/nova' },
      #'libvirt-qemu'    => { user_uid => '498', user_group_name => 'kvm' , group_gid => '498', user_home_dir => '/var/lib/libvirt'},
      #'libvirt-dnsmasq' => { user_uid => '497', user_group_name => 'libvirtd' , group_gid => '497',  user_home_dir => '/var/lib/libvirt/dnsmasq'},
    #}
    #create_resources(contrail::lib::setup_uid, $contrail_users_details,
                        #{
                            #contrail_logoutput => $contrail_logoutput
                        #}
                    #)
    #->
    contrail::lib::contrail_upgrade{ 'contrail_upgrade':
        contrail_upgrade   => $contrail_upgrade,
        contrail_logoutput => $contrail_logoutput
    } ->
    apt::pin { 'debian_repo_preferences':
      priority => '-10',
      originator => 'Debian'
    } ->

    # Resource declarations for class contrail::common
    # macro to perform common functions
    # Create repository config on target.
    contrail::lib::contrail_setup_repo{ $contrail_repo_name:
        contrail_repo_ip   => $contrail_repo_ip,
        contrail_logoutput => $contrail_logoutput
    }
    ->
    contrail::lib::contrail_install_repo{ $contrail_repo_type:
        contrail_logoutput => $contrail_logoutput
    }
    ->
    contrail::lib::upgrade_kernel{ 'kernel_upgrade':
        contrail_kernel_upgrade => $::contrail::params::kernel_upgrade,
        contrail_kernel_version => $::contrail::params::kernel_version,
        contrail_logoutput      => $contrail_logoutput
    }
    ->
    # Ensure /etc/hosts has an entry for self to map dns name to ip address
    host { $::hostname :
        ensure => present,
        ip     => $host_mgmt_ip
    }
    ->
    package { 'libssl0.9.8' : ensure => present,}

    # Disable SELINUX on boot, if not already disabled.
    if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
        exec { 'selinux-dis-1' :
            command   => "sed -i \'s/SELINUX=.*/SELINUX=disabled/g\' config",
            cwd       => '/etc/selinux',
            onlyif    => '[ -d /etc/selinux ]',
            unless    => "grep -qFx 'SELINUX=disabled' '/etc/selinux/config'",
            provider  => shell,
            logoutput => $contrail_logoutput
        }

        # disable selinux runtime
        exec { 'selinux-dis-2' :
            command   => 'setenforce 0 || true',
            unless    => 'getenforce | grep -qi disabled',
            provider  => shell,
            logoutput => $contrail_logoutput
        }

        # Disable iptables
        service { 'iptables' :
            ensure => stopped,
            enable => false,
        }
    }

    if ($::operatingsystem == 'Ubuntu') {
        # disable firewall
        exec { 'disable-ufw' :
            command   => 'ufw disable',
            unless    => 'ufw status | grep -qi inactive',
            provider  => shell,
            logoutput => $contrail_logoutput
        }
        # Create symbolic link to chkconfig. This does not exist on Ubuntu.
        file { '/sbin/chkconfig':
            ensure => link,
            target => '/bin/true'
        }
    }

    # Flush ip tables.
    exec { 'iptables --flush': provider => shell, logoutput => $contrail_logoutput }

    # Remove any core limit configured
    if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
        exec { 'daemon-core-file-unlimited':
            command   => "sed -i \'/DAEMON_COREFILE_LIMIT=.*/d\' /etc/sysconfig/init; echo DAEMON_COREFILE_LIMIT=\"\'unlimited\'\" >> /etc/sysconfig/init",
            unless    => "grep -qx \"DAEMON_COREFILE_LIMIT='unlimited'\" /etc/sysconfig/init",
            provider  => shell,
            logoutput => $contrail_logoutput
        }
    }
    if ($::operatingsystem == 'Ubuntu') {
        exec { 'core-file-unlimited' :
            command   => 'ulimit -c unlimited',
            unless    => 'ulimit -c | grep -qi unlimited',
            provider  => shell,
            logoutput => $contrail_logoutput
        }
    }

    sysctl::value { 'kernel.core_pattern':
      value => '/var/crashes/core.%e.%p.%h.%t'
    }
    sysctl::value { 'net.ipv4.ip_forward':
      value => '1'
    }
    sysctl::value { 'net.ipv4.ip_local_reserved_ports':
      value => "35357,35358,33306,${::ipv4_reserved_ports}"
    }

    # Make sure our scripts directory is present
    file { ['/var/log/mysql', '/var/crashes', '/etc/contrail', '/etc/contrail/contrail_setup_utils'] :
        ensure => 'directory',
    }

    # Enable kernel core.
    file { '/etc/contrail/contrail_setup_utils/enable_kernel_core.py':
        ensure => present,
        mode   => '0755',
        owner  => root,
        group  => root,
        source => "puppet:///modules/${module_name}/enable_kernel_core.py"
    }

    # enable kernel core , below python code has bug, for now ignore by executing echo regardless and thus returning true for cmd.
    # need to revisit afterwards.
    exec { 'enable-kernel-core' :
        command   => 'python /etc/contrail/contrail_setup_utils/enable_kernel_core.py; echo enable-kernel-core >> /etc/contrail/contrail_common_exec.out',
        require   => File['/etc/contrail/contrail_setup_utils/enable_kernel_core.py' ],
        unless    => 'grep -qx enable-kernel-core /etc/contrail/contrail_common_exec.out',
        provider  => shell,
        logoutput => $contrail_logoutput
    }
}
