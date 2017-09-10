class contrail::profile::openstack::keystone(
  $internal_vip       = $::contrail::params::internal_vip,
  $openstack_ip_list  = $::contrail::params::openstack_ip_list,
  $host_control_ip    = $::contrail::params::host_ip,
  $sync_db            = $::contrail::params::os_sync_db,
  $package_sku        = $::contrail::params::package_sku,
  $openstack_verbose  = $::contrail::params::os_verbose,
  $openstack_debug    = $::contrail::params::os_debug,
  $service_password   = $::contrail::params::os_mysql_service_password,
  $allowed_hosts      = $::contrail::params::os_mysql_allowed_hosts,
  $admin_token        = $::contrail::params::os_keystone_admin_token,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
  $rabbit_use_ssl     = $::contrail::params::os_amqp_ssl,
  $kombu_ssl_ca_certs = $::contrail::params::kombu_ssl_ca_certs,
  $kombu_ssl_certfile = $::contrail::params::kombu_ssl_certfile,
  $kombu_ssl_keyfile  = $::contrail::params::kombu_ssl_keyfile,
  $keystone_version   = $::contrail::params::keystone_version,
  $openstack_rabbit_servers        = $::contrail::params::openstack_rabbit_ip_list,
  $keystone_mysql_service_password = $::contrail::params::keystone_mysql_service_password,
  $global_controller_ip_list       = $::contrail::params::global_controller_ip_list,
  $keystone_auth_protocol          = $::contrail::params::keystone_auth_protocol,
  $hostname_lower                  = $::contrail::params::hostname_lower
) {

  if ($keystone_mysql_service_password != "") {
    $service_password_to_use = $keystone_mysql_service_password
  } else {
    $service_password_to_use = $service_password
  }

  class {'::keystone::db::mysql':
    password => $service_password,
    allowed_hosts => $allowed_hosts,
  }

  if ($keystone_version == "v3") {
    file { '/etc/keystone/policy.v3cloudsample.json' :
      ensure  => present,
      content => template("${module_name}/policy.v3cloudsample.json"),
    }
  }
  if ($keystone_auth_protocol == "https") {
    $enable_keystone_ssl = true
  } else {
    $enable_keystone_ssl = false
  }

  if ($internal_vip != "" and $internal_vip != undef) {
    $mysql_port_url = ":3306/keystone"
    $keystone_public_port = "6000"
    $keystone_admin_port  = "35358"
  } else {
    $mysql_port_url = "/keystone"
    $keystone_public_port = "5000"
    $keystone_admin_port = "35357"
  }

  $database_credentials = join([$service_password_to_use, "@", $host_control_ip],'')
  $keystone_db_conn = join(["mysql://keystone:",$database_credentials, $mysql_port_url],'')

  #bootstrap is only for mitaka. kilo is always false
  $tmp_index = inline_template('<%= @openstack_ip_list.index(@host_control_ip) %>')
  if ($tmp_index != nil) {
    $openstack_index = $tmp_index + 1
  }
  # only first node should bootstrap the keystone
  if($openstack_index == '1' ) {
    $bootstrap_keystone = true
  } else {
    $bootstrap_keystone = false
  }
  $paste_config =  ''

  case $package_sku {
    /14\.0/: {
      include keystone::params
      file {["/etc/keystone/ssl", "/etc/keystone/ssl/certs", "/etc/keystone/ssl/private"]:
        owner  => keystone,
        group  => keystone,
        ensure  => directory,
      }
      file { "/etc/keystone/ssl/certs/keystone.pem":
        owner  => keystone,
        group  => keystone,
        source => "puppet:///ssl_certs/${hostname_lower}.pem"
      }
      file { "/etc/keystone/ssl/private/keystonekey.pem":
        owner  => keystone,
        group  => keystone,
        source => "puppet:///ssl_certs/${hostname_lower}-privkey.pem"
      }
      file { "/etc/keystone/ssl/certs/ca.pem":
        owner  => keystone,
        group  => keystone,
        source => "puppet:///ssl_certs/ca-cert.pem"
      }
      class { '::keystone':
        database_connection => $keystone_db_conn,
        service_name    => 'httpd',
        admin_token     => $admin_token,
        public_port     => $keystone_public_port,
        admin_port      => $keystone_admin_port,
        rabbit_hosts    => $openstack_rabbit_servers,
        verbose         => $openstack_verbose,
        debug           => $openstack_debug,
        sync_db         => $sync_db,
        database_idle_timeout   => '180',
        database_min_pool_size  => "100",
        database_max_pool_size  => "700",
        database_max_overflow   => "100",
        database_retry_interval => "-1",
        database_max_retries    => "-1",
        rabbit_use_ssl     => $rabbit_use_ssl,
        kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
        kombu_ssl_certfile => $kombu_ssl_certfile,
        kombu_ssl_keyfile  => $kombu_ssl_keyfile,
        enable_bootstrap   => $bootstrap_keystone,
        enable_ssl         => $enable_keystone_ssl,
        ssl_cert_subject   => "/C=US/ST=Unset/L=Unset/O=Unset/CN=$::fqdn",
        public_endpoint    => "$keystone_auth_protocol://$keystone_ip_to_use:$keystone_public_port/",
        admin_endpoint     => "$keystone_auth_protocol://$keystone_ip_to_use:$keystone_admin_port/",
      } ->
      exec {'keystone disable default site':
        command => "a2dissite keystone",
        provider => shell
      } ->
      file { '/usr/lib/cgi-bin/keystone':
        ensure  => directory,
        owner   => 'keystone',
        group   => 'keystone',
      } ->
      file { "keystone-admin wsgi":
        path    => "/usr/lib/cgi-bin/keystone/keystone-admin",
        source  => "/usr/bin/keystone-wsgi-admin",
        ensure  => link,
        owner   => 'keystone',
        group   => 'keystone',
        mode    => '0644',
        require => File['/usr/lib/cgi-bin/keystone'],
      } ->
      file { "keystone-public wsgi":
        path    => "/usr/lib/cgi-bin/keystone/keystone-public",
        source  => "/usr/bin/keystone-wsgi-public",
        ensure  => link,
        owner   => 'keystone',
        group   => 'keystone',
        mode    => '0644',
        require => File['/usr/lib/cgi-bin/keystone'],
      } ->
     file { 'keystone_main_site' :
        path    => '/etc/apache2/sites-available/10-keystone_wsgi_main.conf',
        content => template("${module_name}/10-keystone_wsgi_main.erb"),
     } ->
     file { 'keystone_admin_site' :
        path    => '/etc/apache2/sites-available/10-keystone_wsgi_admin.conf',
        content => template("${module_name}/10-keystone_wsgi_admin.erb"),
      } ->
    file { "10-keystone_wsgi_main.conf symlink":
      ensure  => link,
      path    => "/etc/apache2/sites-enabled/10-keystone_wsgi_main.conf",
      target  => "/etc/apache2/sites-available/10-keystone_wsgi_main.conf",
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    } ->
    file { "10-keystone_wsgi_admin.conf symlink":
      ensure  => link,
      path    => "/etc/apache2/sites-enabled/10-keystone_wsgi_admin.conf",
      target  => "/etc/apache2/sites-available/10-keystone_wsgi_admin.conf",
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    } ->
    exec {'enable mod-ssl':
      command => "a2enmod ssl",
      provider => shell,
    } ->
    exec {'apache2 restart':
      command => "service apache2 restart",
      provider => shell,
    }

      if ($keystone_version == "v3") {
        keystone_config {
          'oslo_policy/policy_file' : value => "policy.v3cloudsample.json";
        }
      }
    }

    /13\.0/: {
      file { "/etc/keystone/ssl/certs/keystone.pem":
        owner  => keystone,
        group  => keystone,
        source => "puppet:///ssl_certs/${hostname_lower}.pem"
      }
      file { "/etc/keystone/ssl/private/keystonekey.pem":
        owner  => keystone,
        group  => keystone,
        source => "puppet:///ssl_certs/${hostname_lower}-privkey.pem"
      }
      file { "/etc/keystone/ssl/certs/ca.pem":
        owner  => keystone,
        group  => keystone,
        source => "puppet:///ssl_certs/ca-cert.pem"
      }
      
      class { '::keystone':
        database_connection => $keystone_db_conn,
        admin_token     => $admin_token,
        public_port     => $keystone_public_port,
        admin_port      => $keystone_admin_port,
        rabbit_hosts    => $openstack_rabbit_servers,
        verbose         => $openstack_verbose,
        debug           => $openstack_debug,
        sync_db         => $sync_db,
        database_idle_timeout   => '180',
        database_min_pool_size  => "100",
        database_max_pool_size  => "700",
        database_max_overflow   => "100",
        database_retry_interval => "-1",
        database_max_retries    => "-1",
        rabbit_use_ssl     => $rabbit_use_ssl,
        kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
        kombu_ssl_certfile => $kombu_ssl_certfile,
        kombu_ssl_keyfile  => $kombu_ssl_keyfile,
        enable_bootstrap   => $bootstrap_keystone,
        enable_ssl         => $enable_keystone_ssl,
        ssl_cert_subject   => "/C=US/ST=Unset/L=Unset/O=Unset/CN=$::fqdn",
        public_endpoint    => "$keystone_auth_protocol://$keystone_ip_to_use:$keystone_public_port/",
        admin_endpoint     => "$keystone_auth_protocol://$keystone_ip_to_use:$keystone_admin_port/",
      }

      if ($keystone_version == "v3") {
        keystone_config {
          'oslo_policy/policy_file' : value => "policy.v3cloudsample.json";
        }
      }
    }

    default: {
      class { '::keystone':
        database_connection => $keystone_db_conn,
        enable_bootstrap    => false,
        admin_token     => $admin_token,
        paste_config    => $paste_config,
        admin_bind_host => $admin_bind_host,
        public_port     => $keystone_public_port,
        admin_port      => $keystone_admin_port,
        rabbit_hosts    => $openstack_rabbit_servers,
        verbose         => $openstack_verbose,
        debug           => $openstack_debug,
        sync_db         => $sync_db,
        rabbit_use_ssl     => $rabbit_use_ssl,
        kombu_ssl_ca_certs => $kombu_ssl_ca_certs,
        kombu_ssl_certfile => $kombu_ssl_certfile,
        kombu_ssl_keyfile  => $kombu_ssl_keyfile
      }
      keystone_config {
        'database/min_pool_size'     : value => "100";
        'database/max_pool_size'     : value => "700";
        'database/max_overflow'      : value => "100";
        'database/retry_interval'    : value => "5";
        'database/max_retries'       : value => "-1";
        'database/db_max_retries'    : value => "-1";
        'database/db_retry_interval' : value => "1";
        'database/connection_debug'  : value => "10";
        'database/pool_timeout'      : value => "120";
      }
    }
  }

  if (size($::contrail::params::global_controller_ip_list) > 0) {
    keystone_config {
        'cors/allowed_origin'   : value => "*";
    }
  }
}
