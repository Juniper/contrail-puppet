class contrail::compute::install(
  $opencontrail_only = false,
  $enable_lbass =  $::contrail::params::enable_lbass,
) {
    if ( $opencontrail_only == true) {
        package{ 'contrail-openstack-vrouter' :
            ensure => present
        }
    } else {
        #Determine vrouter package to be installed based on the kernel
        #TODO add DPDK support here

        if ($::operatingsystem == 'Ubuntu'){
            if ($::lsbdistrelease == '14.04') {
                if ($::kernelrelease == '3.13.0-40-generic') {
                    $vrouter_pkg = 'contrail-vrouter-3.13.0-40-generic'
                } else {
                    $vrouter_pkg = 'contrail-vrouter-dkms'
                }
            } elsif ($::lsbdistrelease == '12.04') {
                if ($::kernelrelease == '3.13.0-34-generic') {
                    $vrouter_pkg = 'contrail-vrouter-3.13.0-34-generic'
                } else {
                    $vrouter_pkg = 'contrail-vrouter-dkms'
                }
            }
        } else {
            $vrouter_pkg = 'contrail-vrouter'
        }
        # Main code for class starts here
        # Ensure all needed packages are latest
        package { [ $vrouter_pkg, 'contrail-openstack-vrouter'] : ensure => latest}

        if ($enable_lbass == true) {
            package{ ['haproxy', 'iproute'] : ensure => present,}
        }
    }
}
