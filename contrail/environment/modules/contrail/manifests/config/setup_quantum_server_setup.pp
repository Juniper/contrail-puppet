class contrail::config::setup_quantum_server_setup (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    file { '/etc/contrail/quantum-server-setup.sh':
              mode    => '0755',
              owner   => root,
              group   => root,
              source => "puppet:///modules/${module_name}/quantum-server-setup.sh"
    } ->
    exec { 'setup-quantum-server-setup' :
            command  => "/bin/bash /etc/contrail/quantum-server-setup.sh ${::operatingsystem} && echo setup-quantum-server-setup >> /etc/contrail/contrail_config_exec.out",
            unless   => 'grep -qx setup-quantum-server-setup /etc/contrail/contrail_config_exec.out',
            provider => shell
    }
    ->
    notify { "executed setup-quantum-server-setup":; }
}
