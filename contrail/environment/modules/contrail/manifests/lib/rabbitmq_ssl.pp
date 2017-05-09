define contrail::lib::rabbitmq_ssl(
  $rabbit_use_ssl     = $::contrail::params::rabbit_ssl_support,
  $kombu_ssl_ca_certs = $::contrail::params::kombu_ssl_ca_certs,
  $kombu_ssl_certfile = $::contrail::params::kombu_ssl_certfile,
  $kombu_ssl_keyfile  = $::contrail::params::kombu_ssl_keyfile,
){
  if ($rabbit_use_ssl) {
    if !defined(File['/etc/rabbitmq']) {
      file {'/etc/rabbitmq':
        ensure  => directory,
      }
    }
    if !defined(File['/etc/rabbitmq/ssl']) {
      file {'/etc/rabbitmq/ssl':
        ensure  => directory,
      }
    }
    if !defined(File[$kombu_ssl_certfile]) {
      file { $kombu_ssl_certfile:
        source => "puppet:///ssl_certs/$hostname.pem"
      }
    }
    if !defined(File[$kombu_ssl_keyfile]) {
      file { $kombu_ssl_keyfile :
        source => "puppet:///ssl_certs/$hostname-privkey.pem"
      }
    }
    if !defined(File[$kombu_ssl_ca_certs]) {
      file { $kombu_ssl_ca_certs:
        source => "puppet:///ssl_certs/ca-cert.pem"
      }
    }
  }
}
