class contrail::config::setup_pki (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    file { '/etc/contrail_setup_utils/setup-pki.sh' :
                  mode   => '0755',
                  user   => root,
                  group  => root,
                  source => "puppet:///modules/${module_name}/setup-pki.sh"
    } ->
    exec { 'setup-pki' :
                command   => '/etc/contrail_setup_utils/setup-pki.sh /etc/contrail/ssl; echo setup-pki >> /etc/contrail/contrail_config_exec.out',
                unless    => 'grep -qx setup-pki /etc/contrail/contrail_config_exec.out',
                provider  => shell,
                logoutput => $contrail_logoutput
    }
    ->
    notify { "executed setup-pki:; }
}
