# TODO: Document the function

define contrail::lib::upgrade_kernel(
    $contrail_kernel_upgrade,
    $contrail_kernel_version_to_upgrade = $::contrail::params::contrail_dist_kernel_version,
    $contrail_logoutput = false,
) {

    if ($operatingsystem == "Ubuntu" and $contrail_kernel_upgrade == "yes") {


       if ($lsbdistrelease == "12.04") {
           package { 'apparmor' : ensure => '2.7.102-0ubuntu3.10', notify => Reboot["after"], }
       }

/*
       if ($contrail_kernel_version != "" ) {
           $contrail_dist_kernel_version = $contrail_kernel_version
       } else {
           if ($lsbdistrelease == "14.04") {
               $contrail_dist_kernel_version = "3.13.0-40"
           } else {
               $contrail_dist_kernel_version = "3.13.0-34"
               package { 'apparmor' : ensure => '2.7.102-0ubuntu3.10', notify => Reboot["after"], }
           }
       }

*/
       $headers = "linux-headers-${contrail_kernel_version_to_upgrade}"
       $headers_generic = "linux-headers-${contrail_kernel_version_to_upgrade}-generic"
       $image = "linux-image-${contrail_kernel_version_to_upgrade}-generic"
       $image_extra = "linux-image-extra-${contrail_kernel_version_to_upgrade}-generic"

       package { [$headers, $headers_generic, $image,  $image_extra] : ensure => present }
       #->
       #package { $headers_generic : ensure => present, notify => Reboot["after"],  }
       #->
       #package { $image : ensure => present, notify => Reboot["after"],  }
       #->
       #package { $image_extra : ensure => present, notify => Reboot["after"],  }
       ->
       notify { "Before reboot":; }
       ->
       reboot { 'after':
         apply => "immediately",
         timeout => 0,
         message => "Rebooting for kernel upgrade",
         subscribe       => [Package[$image_extra], Package[$headers], Package[$headers_generic], Package[$image]],
       }
       ->
       notify { "After reboot":; }
    } else {
        #TODO for other flavours do nothing
    }

}
#end of upgrade-kernel
