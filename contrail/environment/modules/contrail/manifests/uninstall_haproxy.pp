class contrail::uninstall_haproxy(
    $host_control_ip = $::contrail::params::host_ip,
    $host_roles = $::contrail::params::host_roles,
) inherits ::contrail::params {

    service { 'haproxy' :
	enable => false,
	ensure => stopped,
    }
    ->
#    package { 'haproxy' : ensure => purged}
#    ->
    file { [           
            '/etc/haproxy/haproxy.cfg'
           ]:
        ensure  => absent,
    }

}
