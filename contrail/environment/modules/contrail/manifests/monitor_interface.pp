class contrail::monitor_interface () {
    file { '/etc/monitor_intf.sh' :
        ensure => present,
        mode => 777,
        content => template("${module_name}/monitor_intf.sh.erb")
    } ->
    file { '/usr/lib/systemd/system/monitor_intf.service' :
        ensure => present,
        content => template("${module_name}/monitor_intf.service.erb")
    } ->
    service { 'monitor_intf' :
        enable => true
    }
}
