class contrail::compute::install(
  $opencontrail_only = false,
  $enable_lbass =  $::contrail::params::enable_lbass,
  $enable_dpdk=  $::contrail::params::enable_dpdk,
) {
    $cur_kernel_version = $::kernelrelease
    $dist_kernel_version = "${::contrail::params::contrail_dist_kernel_version}-generic"

    notify{"###DEBUG dist_kernel_version_test  $dist_kernel_version_test ":;}
    notify{"###DEBUG contrail_dist_kernel_version $dist_kernel_version and system kernel version is $cur_kernel_version":;}

    #Temporary work around untill we find out the root cause for inconsistent reboot resource behavior.
    if ((($::contrail::params::kernel_upgrade == 'yes') or
         ($::contrail::params::kernel_upgrade == true)) and $cur_kernel_version != $dist_kernel_version ) {
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
            ensure => present,
            notify => Service['supervisor-vrouter']
        }
    } else {
        #Determine vrouter package to be installed based on the kernel
        #TODO add DPDK support here

        if ($::operatingsystem == 'Ubuntu'){
            if ($::lsbdistrelease == '14.04') {
                notify { "enable_dpdk = ${enable_dpdk}":; }
                if ($enable_dpdk == true ) {
                    notify { "settting up DPDK":; }
                    ->
                    #Might be temporary
                    #create the override and remove it
                    #create an overrride so that supervisor-vrouter doesnt start
                    #when installing the package
                    #This is needed only for dpdk
                    #as the prestart script uses config files
                    file { 'create_supervisor_vrouter_override':
                        path => "/etc/init/supervisor-vrouter.override",
                        ensure => present,
                        content => "manual",
                    }

                    $vrouter_pkg = 'contrail-vrouter-dpdk-init'
                } elsif ($::kernelrelease == '3.13.0-40-generic') {
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
        package { [ $vrouter_pkg, 'contrail-openstack-vrouter'] : ensure => latest, notify => Service['supervisor-vrouter']}

        if ($enable_lbass == true) {
            package{ ['haproxy', 'iproute'] : ensure => present,}
        }
    }
}
