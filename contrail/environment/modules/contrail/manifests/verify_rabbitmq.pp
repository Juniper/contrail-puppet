class contrail::verify_rabbitmq (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
    $master,
    $host_control_ip,
    $amqp_ip_list,
    $amqp_name_list
) {
  if ($master == 'no') {
    $master_node = $amqp_name_list[0]
    notify{"master_node => $master_node":;}

    exec {'check if first rabbitmq node is up':
      command => "rabbitmqctl -n rabbit@${master_node}ctrl cluster_status",
      provider  => shell,
      logoutput => true
    } -> File['/etc/contrail/form_rmq_cluster.sh']
  }
  file { '/etc/contrail/form_rmq_cluster.sh' :
     mode   => '0755',
     group  => root,
     source => "puppet:///modules/${module_name}/form_rmq_cluster.sh"
  } ->
  exec { 'verify-rabbitmq' :
    command   => "/etc/contrail/form_rmq_cluster.sh ${master} ${host_control_ip} ${amqp_ip_list}",
    provider  => shell,
    logoutput => true,
    notify    => Service['rabbitmq-server'],
  }
  ->
  notify { "executed verify-rabbitmq":; }
}
