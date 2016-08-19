class contrail::uninstall_keepalived (
    $host_control_ip = $::contrail::params::host_ip,
    $host_roles = $::contrail::params::host_roles,
) inherits ::contrail::params {

    service { "keepalived" :
	ensure => stopped,
    }
    ->
   # package { 'keepalived' : ensure => purged}
   # ->
    file { [           
            '/etc/keepalived/keepalived.conf'
           ]:
        ensure  => absent,
    }
}
