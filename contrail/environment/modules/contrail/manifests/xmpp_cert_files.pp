class contrail::xmpp_cert_files(
) {
    file { ["/etc/contrail/ssl",
            "/etc/contrail/ssl/certs",
            "/etc/contrail/ssl/private" ] :
        ensure => directory
    }
    file { '/etc/contrail/ssl/certs/server.pem' :
        require => File['/etc/contrail/ssl/certs'],
        source => "puppet:///ssl_certs/$hostname.pem"
    }
    file { '/etc/contrail/ssl/private/server-privkey.pem' :
        require => File['/etc/contrail/ssl/private'],
        source => "puppet:///ssl_certs/$hostname-privkey.pem"
    }
    file { '/etc/contrail/ssl/certs/ca-cert.pem' :
        require => File['/etc/contrail/ssl/certs'],
        source => "puppet:///ssl_certs/ca-cert.pem"
    }
}
