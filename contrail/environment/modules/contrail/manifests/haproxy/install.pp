class contrail::haproxy::install() {
    package { 'haproxy' : ensure => present,}
}
