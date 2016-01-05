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
    include ::contrail

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
    contrail::lib::contrail_upgrade{ 'contrail_upgrade':
        contrail_upgrade   => $contrail_upgrade,
        contrail_logoutput => $contrail_logoutput
    } ->
    apt::pin { 'debian_repo_preferences':
      priority => '-10',
      originator => 'Debian'
    } ->
    apt::pin { 'contrail_repo_preferences':
      priority => '999',
      codename => 'contrail'
    } ->

    # Resource declarations for class contrail::common
    # macro to perform common functions
    # Create repository config on target.
    contrail::lib::contrail_setup_repo{ $contrail_repo_name:
        contrail_repo_ip   => $contrail_repo_ip,
        contrail_logoutput => $contrail_logoutput
    }
    ->
    contrail::lib::contrail_install_repo{ "contrail_install_repo":
        contrail_logoutput => $contrail_logoutput
    }
    ->
    contrail::lib::upgrade_kernel{ 'kernel_upgrade':
        contrail_kernel_upgrade => $::contrail::params::kernel_upgrade,
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
        # Set SELINUX as disabled in selinux config
        contrail::lib::augeas_conf_set { 'SELINUX':
             config_file => '/etc/selinux/config',
             settings_hash => { 'SELINUX' => 'disabled',},
             lens_to_use => 'properties.lns',
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
        contrail::lib::augeas_conf_set { 'DAEMON_COREFILE_LIMIT':
            config_file => '/etc/sysconfig/init',
            settings_hash => { 'DAEMON_COREFILE_LIMIT' => 'unlimited',},
            lens_to_use => 'properties.lns',
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
