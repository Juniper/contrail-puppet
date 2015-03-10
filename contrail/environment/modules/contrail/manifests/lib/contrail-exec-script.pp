#source ha proxy files
define contrail::lib::contrail-exec-script(
    $script_name,
    $args,
    $contrail_logoutput = false,
) {
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
        logoutput => $contrail_logoutput,
        unless  => "grep -qx script-exec${script_name} /etc/contrail/contrail_common_exec.out",
        require => File["/etc/contrail/${script_name}"]
    }
}
