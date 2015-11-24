class contrail::compute::install(
  $opencontrail_only = false,
  $enable_lbass =  $::contrail::params::enable_lbass,
) {
    $cur_kernel_version = $::kernelrelease
    $dist_kernel_version = "${::contrail::params::contrail_dist_kernel_version}-generic"
    
    notify{"###DEBUG dist_kernel_version_test  $dist_kernel_version_test ":;}
    notify{"###DEBUG contrail_dist_kernel_version $dist_kernel_version and system kernel version is $cur_kernel_version":;}
    
    #Temporary work around untill we find out the root cause for inconsistent reboot resource behavior.
    if ($::contrail::params::kernel_upgrade == 'yes' and $cur_kernel_version != $dist_kernel_version ) {
      notify{"###DEBUG inside if contrail_dist_kernel_version $dist_kernel_version and system kernel version is $cur_kernel_version":;}
      notify{"Missed reboot for kernel Upgrade, Initiating a reboot":;}
      ->
      reboot { 'after_notify':
         apply => "immediately",
	 timeout => 0,
	 message => "Rebooting for kernel upgrade",
	 subscribe       => Notify["Missed reboot for kernel Upgrade, Initiating a reboot"],
      }
    } else {
      notify{"Kernel Update Successful!":;}
    }

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
