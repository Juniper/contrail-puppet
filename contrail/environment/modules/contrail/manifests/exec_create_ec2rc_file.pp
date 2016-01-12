class contrail::exec_create_ec2rc_file (
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    # Create ec2rc file
    file { '/opt/contrail/bin/contrail-create-ec2rc.sh' :
        ensure => present,
        mode   => '0755',
        group  => root,
        source => "puppet:///modules/${module_name}/contrail-create-ec2rc.sh"
    }
    ->
    exec { 'exec_create_ec2rc_file':
            command   => './contrail-create-ec2rc.sh',
            cwd       => '/opt/contrail/bin/',
            provider  => shell,
            logoutput => $contrail_logoutput
    }
    ->
    notify { "executed exec_create_ec2rc_file" :; }
}

