# == Class: contrail::openstack

# This class is used to configure software and services required
# to run openstack module of contrail software suit.
#
# === Parameters:
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
class contrail::uninstall_openstack (
    $mysql_root_password = $::contrail::params::mysql_root_password,
    $host_control_ip = $::contrail::params::host_ip,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    include ::contrail::params

    # Set all variables as needed for config file using the class parameters.
    # if contrail_internal_vip is "", but internal_vip is not "", set contrail_internal_vip
    # to internal_vip.
/*
    $conductor_idx_cmd = "source /etc/contrail/openstackrc && /usr/bin/nova service-list | /bin/grep $hostname | /bin/grep nova-conductor | /usr/bin/awk \'{print \$2}\' "
    $consoleauth_idx_cmd = "source /etc/contrail/openstackrc && /usr/bin/nova service-list | /bin/grep $hostname | /bin/grep nova-consoleauth | /usr/bin/awk \'{print \$2}\' "
    $scheduler_idx_cmd = "source /etc/contrail/openstackrc && /usr/bin/nova service-list | /bin/grep $hostname | /bin/grep nova-scheduler | /usr/bin/awk \'{print \$2}\' "
    $console_idx_cmd = "source /etc/contrail/openstackrc && /usr/bin/nova service-list | /bin/grep $hostname | /bin/grep nova-console | /usr/bin/awk \'{print \$2}\' "

    $conductor_idx = generate("/bin/bash", "-c", $conductor_idx_cmd)
    $consoleauth_idx = generate("/bin/bash", "-c", $consoleauth_idx_cmd)
    $scheduler_idx = generate("/bin/bash", "-c", $scheduler_idx_cmd)
    $console_idx = generate("/bin/bash", "-c", $console_idx_cmd)
  */
    contrail::lib::report_status { 'uninstall_openstack_started':
        state              => 'uninstall_openstack_started',
        contrail_logoutput => $contrail_logoutput }
    ->
    exec { "delete_conductor":
        command => "/bin/bash -c \"source /etc/contrail/openstackrc && nova service-delete ${conductor_idx}\" && echo delete_conductor >> /etc/contrail/contrail_openstack_exec.out",
        unless => "grep -qx delete_conductor /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => $contrail_logoutput
    }
    ->
    exec { "delete_consoleauth":
        command => "/bin/bash -c \"source /etc/contrail/openstackrc && nova service-delete ${consoleauth_idx}\" && echo delete_consoleauth >> /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        unless => "grep -qx delete_consoleauth /etc/contrail/contrail_openstack_exec.out",
        logoutput => $contrail_logoutput
    }
    ->
    exec { "delete_scheduler":
        command => "/bin/bash -c \"source /etc/contrail/openstackrc && nova service-delete ${scheduler_idx}\" && echo delete_scheduler >> /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        unless => "grep -qx delete_scheduler /etc/contrail/contrail_openstack_exec.out",
        logoutput => $contrail_logoutput
    }
    ->
    exec { "delete_console":
        command => "/bin/bash -c \"source /etc/contrail/openstackrc && nova service-delete ${console_idx}\" && echo delete_console >> /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        unless => "grep -qx delete_console /etc/contrail/contrail_openstack_exec.out",
        logoutput => $contrail_logoutput
    }
    ->
    exec { "remove_mysql_cmon_user":
        command => "/usr/bin/mysql -uroot -p${mysql_root_password} -e 'DROP user cmon@$host_control_ip\' && echo remove_mysql_cmon_user >> /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        unless => "grep -qx remove_mysql_cmon_user /etc/contrail/contrail_openstack_exec.out",
        logoutput => $contrail_logoutput
    }

    ->
    exec { "remove_mysql_root_user":
        command => "/usr/bin/mysql -uroot -p${mysql_root_password} -e 'DROP user root@$host_control_ip' && echo remove_mysql_root_user >> /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        unless => "grep -qx remove_mysql_root_user /etc/contrail/contrail_openstack_exec.out",
        logoutput => $contrail_logoutput
    }

    ->
    exec { "remove_mysql_flush_privellages":
        command => "/usr/bin/mysql -uroot -p${mysql_root_password} -e 'FLUSH PRIVILEGES' && echo remove_mysql_flush_privellages >> /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        unless => "grep -qx remove_mysql_flush_privellages /etc/contrail/contrail_openstack_exec.out",
        logoutput => $contrail_logoutput
    }
    ->

    service { ['contrail-hamon','cmon', 'apache2', 'mysql'] :
        ensure    => false ,
        enable    => false,
    }
    ->
    # Ensure all needed packages are present
    package { ['contrail-openstack' ,'apache2' ,'memcached','glance-api','glance-registry','cinder-api','cinder-common','cinder-scheduler','python-nova','nova-common','python-numpy','heat-common','heat-api','heat-api-cfn','openstack-dashboard','nova-api','nova-novncproxy','nova-scheduler','nova-objectstore','nova-consoleauth','nova-conductor','contrail-openstack-dashboard', 'mysql', 'keystone', 'mysql-server-wsrep','mysql-common'] :
        ensure => purged,
        notify => ["Exec[apt_auto_remove_openstack]"],
    }
    ->
    #if puppet provides glob use that
    exec { "remove_mysql_log_files":
        command => "rm -f /var/lib/mysql/ib_logfile*",
        provider => shell,
        logoutput => $contrail_logoutput
    }

    ->
    /*
    # Ensure all needed packages are present
    package { ['contrail-openstack','nova*','glance*','keystone*','memcache*','cmon*','mysql*'] :
        ensure => purged,
        provider => aptitude,
        notify => ["Exec[apt_auto_remove_openstack]"],
    }
    ->
    */
    exec { "apt_auto_remove_openstack":
        command => "apt-get autoremove -y --purge",
        provider => shell,
        logoutput => $contrail_logoutput
    }

    ->

    contrail::lib::report_status { 'uninstall_openstack_completed':
        state              => 'uninstall_openstack_completed',
        contrail_logoutput => $contrail_logoutput
    }

}
