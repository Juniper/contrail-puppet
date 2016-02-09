class contrail::remove_mysql_cmon_user (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $mysql_root_password,
    $host_control_ip
) {
    exec { "remove_mysql_cmon_user":
        command => "/usr/bin/mysql -uroot -p${mysql_root_password} -e 'DROP user cmon@${host_control_ip}\' && echo remove_mysql_cmon_user >> /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        unless => 'echo \'! mysql -uroot -p${mysql_root_password} -e "SHOW GRANTS FOR cmon@${host_control_ip}"\' | bash',
        logoutput => $contrail_logoutput
    }
    ->
    notify { "executed remove_mysql_cmon_user" :; }
}

