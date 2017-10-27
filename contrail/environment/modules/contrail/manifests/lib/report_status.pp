#TODO: Document the class
define contrail::lib::report_status(
    $state = $name,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
  exec { "contrail-status-${state}" :
    command   => "mkdir -p /etc/contrail/ && wget -q --post-data='' 'http://${::servername}:9002/server_status?server_id=${::hostname}&state=${state}' -O /dev/null && echo contrail-status-${state} >> /etc/contrail/contrail_common_exec.out",
    provider  => shell,
    logoutput => $contrail_logoutput
  }
}
