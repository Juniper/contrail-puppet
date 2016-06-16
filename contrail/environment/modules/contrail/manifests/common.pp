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
) {
    include ::contrail
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

    # All Resources for this class are below.
    notify { "**** ${module_name} - host_mgmt_ip = ${host_mgmt_ip}": ; } ->
    notify { "**** ${module_name} - contrail_repo_name = ${contrail_repo_name}": ; } ->
    notify { "**** ${module_name} - contrail_repo_ip = ${contrail_repo_ip}": ; } ->
    notify { "**** ${module_name} - contrail_repo_type = ${contrail_repo_type}": ; } ->
    Group['nova', 'kvm', 'libvirtd'] ->
    User['nova', 'libvirt-qemu', 'libvirt-dnsmasq'] ->
    contrail::lib::contrail_upgrade{ 'contrail_upgrade':
        contrail_upgrade   => $contrail_upgrade,
        contrail_logoutput => $contrail_logoutput,
        upgrade_needed => $upgrade_needed
    } ->
    apt::pin { 'debian_repo_preferences':
      priority => '-10',
      originator => 'Debian'
    } ->
    apt::pin { 'contrail_repo_preferences':
      priority => '999',
      codename => 'contrail'
    } ->
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
    # Ensure /etc/hosts has an entry for self to map dns name to ip address
    host { $::hostname :
        ensure => present,
        ip     => $host_mgmt_ip
    } ->
    package { 'libssl0.9.8' : ensure => present,} ->
    sysctl::value { 'kernel.core_pattern':
      value => '/var/crashes/core.%e.%p.%h.%t'
    } ->
    sysctl::value { 'net.ipv4.ip_forward':
      value => '1'
    } ->
    sysctl::value { 'net.ipv4.ip_local_reserved_ports':
      value => "35357,35358,33306,${::ipv4_reserved_ports}"
    } ->
    # Make sure our scripts directory is present
    file { ['/var/log/mysql', '/var/crashes', '/etc/contrail', '/etc/contrail/contrail_setup_utils'] :
        ensure => 'directory',
    } ->
    Class['::contrail::enable_kernel_core']

    # Disable SELINUX on boot, if not already disabled.
    if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
        Package['libssl0.9.8']->
        # Set SELINUX as disabled in selinux config
        contrail::lib::augeas_conf_set { 'SELINUX':
             config_file => '/etc/selinux/config',
             settings_hash => { 'SELINUX' => 'disabled',},
             lens_to_use => 'properties.lns',
        } ->
        Class['::contrail::disable_selinux']->
        # Disable iptables
        service { 'iptables' :
            ensure => stopped,
            enable => false,
        } ->
        Class['::contrail::flush_iptables'] ->
        # Remove any core limit configured
        contrail::lib::augeas_conf_set { 'DAEMON_COREFILE_LIMIT':
            config_file => '/etc/sysconfig/init',
            settings_hash => { 'DAEMON_COREFILE_LIMIT' => 'unlimited',},
            lens_to_use => 'properties.lns',
        } ->
        Sysctl::Value['kernel.core_pattern']
        contain ::contrail::disable_selinux
    }

    if ($::operatingsystem == 'Ubuntu') {
        Package['libssl0.9.8']->Class['::contrail::disable_ufw']->
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
}
