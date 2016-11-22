define contrail::lib::setup_qos(
    $qos_hash,
) {

  if (!empty($qos_hash)) {
    $qos_nic_hash = $qos_hash[$title]

    notify { "qos_hash_${title} = ${qos_hash}":; } ->
    notify { "title_${title} = ${title}":; } ->
    notify { "qos_nic_hash_${title} = ${qos_nic_hash}":; }
    ->
    contrail_vrouter_agent_config {
      "QUEUE-${title}/logical_queue" : value => $qos_nic_hash["logical_queue"];
      "QUEUE-${title}/scheduling" : value => $qos_nic_hash["scheduling"];
      "QUEUE-${title}/bandwidth" : value => $qos_nic_hash["bandwidth"];
    }

    if ($qos_nic_hash["default"]) {
      contrail_vrouter_agent_config {
        'QOS/logical_queue' : value => $qos_nic_hash["logical_queue"];
      }
    }

  }
}
