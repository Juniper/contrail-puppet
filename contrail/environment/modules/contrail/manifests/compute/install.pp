class contrail::compute::install(
  $opencontrail_only = false,
  $default_trusty_kernel = $::contrail::params::default_trusty_kernel,
  $enable_lbaas =  $::contrail::params::enable_lbaas,
  $enable_dpdk=  $::contrail::params::enable_dpdk,
) {
    $cur_kernel_version = $::kernelrelease
    $dist_kernel_version = "${::contrail::params::contrail_dist_kernel_version}-generic"

    notify{"compute_notify_1": name => "###DEBUG dist_kernel_version_test  $dist_kernel_version_test ";} ->
    notify{"compute_notify_2": name => "###DEBUG contrail_dist_kernel_version $dist_kernel_version and system kernel version is $cur_kernel_version";}

    #Temporary work around untill we find out the root cause for inconsistent reboot resource behavior.
    if ((($::contrail::params::kernel_upgrade == 'yes') or
         ($::contrail::params::kernel_upgrade == true)) and $cur_kernel_version != $dist_kernel_version ) {
      Notify["compute_notify_2"]->
      notify{"compute_notify_3": name => "###DEBUG inside if contrail_dist_kernel_version $dist_kernel_version and system kernel version is $cur_kernel_version";} ->
      notify{"compute_notify_4": name => "Missed reboot for kernel Upgrade, Initiating a reboot";}
      ->
      reboot { 'after_notify':
         apply => "immediately",
	 timeout => 0,
	 message => "Rebooting for kernel upgrade",
	 subscribe       => Notify["Missed reboot for kernel Upgrade, Initiating a reboot"],
      }
    } else {
      Notify["compute_notify_2"]->
      notify{"compute_notify_5": name => "Kernel Update Successful!";}
    }

    if ( $opencontrail_only == true) {
        Notify["compute_notify_2"]->
        package{ 'contrail-openstack-vrouter' :
            ensure => latest,
            notify => Service['supervisor-vrouter']
        }
    } else {
        #Determine vrouter package to be installed based on the kernel
        #TODO add DPDK support here

        if ($::operatingsystem == 'Ubuntu'){
            if ($::lsbdistrelease == '14.04') {
                notify {"compute_notify_6": name => "enable_dpdk = ${enable_dpdk}"; }
                if ($enable_dpdk == true ) {
                    $vrouter_pkg = 'contrail-vrouter-dpdk-init'
                    Notify["compute_notify_2"]->
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
                    } ->
                    Package[$vrouter_pkg, 'contrail-openstack-vrouter']

                } elsif ($::kernelrelease == '${default_trusty_kernel}-generic') {
                    $vrouter_pkg = 'contrail-vrouter-${default_trusty_kernel}-generic'
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

        if ($enable_lbaas == true) {
            Package[$vrouter_pkg, 'contrail-openstack-vrouter'] ->
            package{ ['haproxy', 'iproute'] : ensure => present,}
        }
    }
}
