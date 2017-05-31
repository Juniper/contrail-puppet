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
    $host_roles = $::contrail::params::host_roles,
    $upgrade_needed = $::contrail::params::upgrade_needed,
    $ssl_package    = $::contrail::params::ssl_package,
    $enable_dpdk    = $::contrail::params::enable_dpdk,
    $contrail_hostnames   = $::contrail::params::hostnames['hostnames'],
) {
    include ::contrail
    $contrail_group_details = {
      'nova'     => { gid => '499'},
      'kvm'      => { gid => '498'},
      'libvirtd' => { gid => '497'},
      'ceph'     => { gid => '496'},
      'glance'   => { gid => '495'},
    }
    $contrail_users_details = {
      'nova'            => { ensure => present, uid => '499', gid => '499', home => '/var/lib/nova' , managehome => true, shell => '/bin/bash'},
      'libvirt-qemu'    => { ensure => present, uid => '498', gid => '498', home => '/var/lib/libvirt',  managehome => true},
      'libvirt-dnsmasq' => { ensure => present, uid => '497', gid => '497', home => '/var/lib/libvirt/dnsmasq',  managehome => true},
      'ceph'            => { ensure => present, uid => '496', gid => '496', home => '/var/lib/ceph',  managehome => true},
      'glance'          => { ensure => present, uid => '495', gid => '495', home => '/var/lib/glance',  managehome => true},
    }

    file { '/tmp/change_id.sh' :
        ensure => present,
        mode   => '0755',
        group  => root,
        source => "puppet:///modules/${module_name}/change_id.sh"
    } ->
    exec {"change-glance-id":
      command   => "/tmp/change_id.sh",
      provider  => shell,
      logoutput => true
    }
    Exec['change-glance-id'] -> Group<| name=='glance' |>
    Exec['change-glance-id'] -> User<| name=='glance' |>

    create_resources(group, $contrail_group_details)
    create_resources(user, $contrail_users_details)
    create_resources(host, $contrail_hostnames)
    Contrail::Lib::Contrail_setup_repo <||> -> Package<||>
    if ($::operatingsystem == 'Ubuntu'){
      if ($::lsbdistrelease == '14.04' or $::lsbdistrelease == '16.04') {
        if ($enable_dpdk == true ) {
          contrail::lib::setup_dpdk_depends{ 'dpdk_depends':}
        }
      }
    }

    # All Resources for this class are below.
    Group['nova', 'kvm', 'libvirtd'] ->
    User['nova', 'libvirt-qemu', 'libvirt-dnsmasq'] ->
    contrail::lib::contrail_upgrade{ 'contrail_upgrade':
      contrail_upgrade   => $contrail_upgrade,
      contrail_logoutput => $contrail_logoutput
    }
    if 'Ubuntu' == $::operatingsystem {
        apt::pin { 'debian_repo_preferences':
          priority => '-10',
          originator => 'Debian'
        } ->
        apt::pin { 'contrail_repo_preferences':
          priority => '999',
          codename => 'contrail'
        }
    }
    # Create repository config on target.
    contrail::lib::contrail_setup_repo{ $contrail_repo_name:
      contrail_repo_ip   => $contrail_repo_ip,
      contrail_logoutput => $contrail_logoutput
    } ->
    contrail::lib::contrail_install_repo{ "contrail_install_repo":
      contrail_logoutput => $contrail_logoutput
    } ->
    contrail::lib::upgrade_kernel{ 'kernel_upgrade':
      contrail_kernel_upgrade => $::contrail::params::kernel_upgrade,
      contrail_logoutput      => $contrail_logoutput
    } ->
    sysctl::value { 
      'kernel.core_pattern': value => '/var/crashes/core.%e.%p.%h.%t';
      'net.ipv4.ip_forward': value => '1';
      'net.ipv4.ip_local_reserved_ports': value => "35357,35358,33306,${::ipv4_reserved_ports}";
    } ->
    # Make sure our scripts directory is present
    file { ['/var/log/mysql', '/var/crashes', '/etc/contrail', '/etc/contrail/contrail_setup_utils'] :
        ensure => 'directory',
    } ->
    Class['::contrail::enable_kernel_core']

    if ($::lsbdistrelease != '16.04') {
      package { $ssl_package :
        ensure => present,
      }
      Contrail::Lib::Upgrade_kernel['kernel_upgrade']
      -> Package[$ssl_package]
      -> Sysctl::Value['kernel.core_pattern']

      Package[$ssl_package]
      -> Class['::contrail::disable_ufw']
    }

    # Disable SELINUX on boot, if not already disabled.
    if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
        Package[$ssl_package]->
        # Set SELINUX as disabled in selinux config
        contrail::lib::augeas_conf_set { 'SELINUX':
             config_file => '/etc/selinux/config',
             settings_hash => { 'SELINUX' => 'disabled',},
             lens_to_use => 'properties.lns',
        } ->
        Class['::contrail::disable_selinux']->
        Class['::contrail::flush_iptables'] ->
        # Remove any core limit configured
        contrail::lib::augeas_conf_set { 'DAEMON_COREFILE_LIMIT':
            config_file => '/etc/sysconfig/init',
            settings_hash => { 'DAEMON_COREFILE_LIMIT' => 'unlimited',},
            lens_to_use => 'properties.lns',
        } ->
        Sysctl::Value['kernel.core_pattern']
        package { 'yum-plugin-priorities' : ensure => present,} ->
        # add check_obsoletes flag off, for bug #1650463
        exec { "/etc/yum/pluginconf.d/priorities.conf":
            command => "echo 'check_obsoletes=1' >> /etc/yum/pluginconf.d/priorities.conf && echo exec-yum-priorities-fix >> /etc/contrail/exec-yum-pririties-fix.out",
            provider => shell,
            unless => "grep -qx exec-yum-priorities-fix /etc/contrail/exec-yum-pririties-fix.out",
            logoutput => true
        }
        contain ::contrail::disable_selinux
    }

    if ($::operatingsystem == 'Ubuntu') {
        Class['::contrail::disable_ufw']->
        # Create symbolic link to chkconfig. This does not exist on Ubuntu.
        file { '/sbin/chkconfig':
            ensure => link,
            target => '/bin/true'
        } ->
        Class['::contrail::flush_iptables'] ->
        Class['::contrail::core_file_unlimited']->
        Sysctl::Value['kernel.core_pattern']
        contain ::contrail::disable_ufw
        contain ::contrail::core_file_unlimited
    }
    contain ::contrail::flush_iptables
    contain ::contrail::enable_kernel_core
    if (("config" in $host_roles) or ("database" in $host_roles) or ("control" in $host_roles) or ("controller" in $host_roles)) {
      contrail::lib::augeas_security_limits_conf_set { 
          "root-soft": title => "root-soft", domain => root, type => soft, item => nofile, value =>  65535;
          "root-hard": title => "root-hard", domain => root, type => hard, item => nofile, value =>  65535;
          "*-hard-nofile": title => "*-hard-nofile", domain => "*", type => hard, item => nofile, value =>  65535;
          "*-soft-nofile": title => "*-soft-nofile", domain => "*", type => soft, item => nofile, value =>  65535;
          "*-hard-nproc": title => "*-hard-nproc", domain => "*", type => hard, item => nproc, value =>  65535;
          "*-soft-nofile-2": title => "*-soft-nofile-2", domain => "*", type => soft, item => nofile, value =>  65535;
       }
    }
}
