class contrail::rabbitmq (
  $host_control_ip   = $::contrail::params::host_ip,
  $control_ip_list   = $::contrail::params::control_ip_list,
  $haproxy           = $::contrail::params::haproxy,
  $amqp_server_ip    = $::contrail::params::amqp_server_ip,
  $config_ip_list    = $::contrail::params::config_ip_list,
  $openstack_ip_list = $::contrail::params::openstack_ip_list,
  $config_name_list  = $::contrail::params::config_name_list,
  $config_ip         = $::contrail::params::config_ip_to_use,
  $collector_ip      = $::contrail::params::collector_ip_to_use,
  $uuid              = $::contrail::params::uuid,
  $openstack_name_list     = $::contrail::params::openstack_name_list,
  $contrail_amqp_ip_list   = $::contrail::params::contrail_amqp_ip_list,
  $openstack_manage_amqp   = $::contrail::params::openstack_manage_amqp,
  $contrail_rabbit_servers = $::contrail::params::contrail_rabbit_servers,
  $rabbitmq_password       = $::contrail::params::os_rabbitmq_password,
  $rabbitmq_user           = $::contrail::params::os_rabbitmq_user,
  $contrail_logoutput      = $::contrail::params::contrail_logoutput,
  $contrail_amqp_ssl       = $::contrail::params::contrail_amqp_ssl,
  $os_amqp_ssl             = $::contrail::params::os_amqp_ssl,
) {
  # Check to see if amqp_ip_list was passed by user. If yes, rabbitmq provisioning can be skipped
  if ((size($contrail_amqp_ip_list) == 0) or ($openstack_manage_amqp and ($host_control_ip in $openstack_ip_list)) ) {
    if ($openstack_manage_amqp and ($host_control_ip in $openstack_ip_list)) {
      $amqp_ip_list = $openstack_ip_list
      $amqp_name_list = $openstack_name_list
      $rabbit_use_ssl = $os_amqp_ssl
    } else {
      $amqp_ip_list = $config_ip_list
      $amqp_name_list = $config_name_list
      $rabbit_use_ssl = $contrail_amqp_ssl
    }

    # Set number of amqp nodes
    $amqp_number = size($amqp_ip_list)

    if ( $host_control_ip == $amqp_ip_list[0]) {
      $master = 'yes'
    } else {
      $master = 'no'
    }

    $amqp_ip_list_shell = join($amqp_ip_list,",")
    $amqp_name_list_shell = join($amqp_name_list, ",")
    $rabbit_env = "NODE_IP_ADDRESS=${host_control_ip}\nNODENAME=rabbit@${::hostname}ctrl\n"

    contrail::lib::rabbitmq_ssl{'rabbit_setup':rabbit_use_ssl => $rabbit_use_ssl}

    if ($::operatingsystem == 'Ubuntu') {
      file {'/etc/default/rabbitmq-server':
        ensure => present,
      } ->
      file_line { 'RABBITMQ-SERVER-ULIMIT':
        path => '/etc/default/rabbitmq-server',
        line => 'ulimit -n 10240',
      } ~> Service['rabbitmq-server']
    }

    if !defined(Service['rabbitmq-server']) {
      service { 'rabbitmq-server':
        ensure => running,
        enable => true
      }
    }

    # Handle rabbitmq.config changes
    file {'/var/lib/rabbitmq/.erlang.cookie':
      mode    => '0400',
      owner   => rabbitmq,
      group   => rabbitmq,
      content => $uuid
    }->
    file { '/etc/rabbitmq/rabbitmq.config' :
      content => template("${module_name}/rabbitmq_config.erb"),
    }
    ->
    file { '/etc/rabbitmq/rabbitmq-env.conf' :
      mode    => '0755',
      group   => root,
      content => $rabbit_env,
    }
    ->
    class {'::contrail::add_etc_hosts':
      amqp_ip_list_shell => $amqp_ip_list_shell,
      amqp_name_list_shell => $amqp_name_list_shell
    } ->

    class {'::contrail::verify_rabbitmq':
      master => $master,
      host_control_ip => $host_control_ip,
      amqp_ip_list => $amqp_ip_list
    }
    contain ::contrail::verify_rabbitmq
    contain ::contrail::add_etc_hosts
  } else {
    contrail::lib::rabbitmq_ssl{'rabbit_setup_config':rabbit_use_ssl => $contrail_amqp_ssl}
  }
}
