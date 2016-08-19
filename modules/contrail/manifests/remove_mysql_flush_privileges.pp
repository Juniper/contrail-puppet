class contrail::remove_mysql_flush_privileges (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $mysql_root_password
) {
    exec { "remove_mysql_flush_privileges":
        command => "/usr/bin/mysql -uroot -p${mysql_root_password} -e 'FLUSH PRIVILEGES' && echo remove_mysql_flush_privileges >> /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        unless => "grep -qx remove_mysql_flush_privileges /etc/contrail/contrail_openstack_exec.out",
        logoutput => $contrail_logoutput
    }
    ->
    notify { "executed remove_mysql_flush_privileges" :; }
}

