class contrail::remove_mysql_log_files (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    exec { "remove_mysql_log_files":
        command => "rm -f /var/lib/mysql/ib_logfile*",
        provider => shell,
        logoutput => $contrail_logoutput
    }
    ->
    notify { "executed remove_mysql_log_files" :; }
}

