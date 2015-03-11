define contrail::lib::fix-memcache-conf (
    $listen_ip = "",
    $contrail_logoutput = false,
) {
        file { "/opt/contrail/bin/fix-mem-cache.py":
            ensure  => present,
            mode => 0755,
            owner => root,
            group => root,
            source => "puppet:///modules/$module_name/fix-mem-cache.py"
        }
        ->
        exec { "exec-fix-memcache":
            command => "python /opt/contrail/bin/fix-mem-cache.py $listen_ip && echo exec-fix-memcache >> /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => $contrail_logoutput,
            unless  => "grep -qx exec-fix-memcache  /etc/contrail/contrail_openstack_exec.out"
        }

}

