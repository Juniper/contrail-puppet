#source ha proxy files
define contrail::lib::haproxy-cfg(
    $server_id,
    $contrail_logoutput = false,
) {
    file { "/etc/haproxy/haproxy.cfg":
	ensure  => present,
	mode => 0755,
	owner => root,
	group => root,
	source => "puppet:///modules/$module_name/$server_id.cfg"
    }
    exec { "haproxy-exec":
	command => "sudo sed -i 's/ENABLED=.*/ENABLED=1/g' /etc/default/haproxy",
	provider => shell,
	logoutput => $contrail_logoutput,
	require => File["/etc/haproxy/haproxy.cfg"]
    }
    service { "haproxy" :
	enable => true,
	require => [File["/etc/default/haproxy"],
		    File["/etc/haproxy/haproxy.cfg"]],
	ensure => running
	}
}
