# TODO: Document the function

define contrail::lib::upgrade_kernel(
    $contrail_kernel_upgrade,
    $contrail_kernel_version,
    $contrail_logoutput = false,
) {

    if ($operatingsystem == "Ubuntu" and $contrail_kernel_upgrade == "yes")
    {
        if ($lsbdistrelease == "14.04") {
            if ($contrail_kernel_version == "" ) {
                $contrail_dist_kernel_version = "3.13.0-40"
            } else {
                $contrail_dist_kernel_version = $contrail_kernel_version
            }

            $headers = "linux-headers-${contrail_dist_kernel_version}"
            $headers_generic = "linux-headers-${contrail_dist_kernel_version}-generic"
            $image = "linux-image-${contrail_dist_kernel_version}-generic"
            $image_extra = "linux-image-extra-${contrail_dist_kernel_version}-generic"

            package { $headers : ensure => present, notify => Reboot["after"],  }
            ->
            package { $headers_generic : ensure => present, notify => Reboot["after"],  }
            ->
            package { $image : ensure => present, notify => Reboot["after"],  }
            ->
            package { $image_extra : ensure => present, notify => Reboot["after"],  }
            ->
            reboot { 'after':
              apply => "immediately",
              timeout => 0,
              message => "Rebooting for kernel upgrade",
              subscribe       => Package[$image_extra],
            }
        } else {
            if ($contrail_kernel_version == "" ) {
                $contrail_dist_kernel_version = "3.13.0-34"
            } else {
                $contrail_dist_kernel_version = $contrail_kernel_version
            }

            $headers = "linux-headers-${contrail_dist_kernel_version}"
            $headers_generic = "linux-headers-${contrail_dist_kernel_version}-generic"
            $image = "linux-image-${contrail_dist_kernel_version}-generic"
            $image_extra = "linux-image-extra-${contrail_dist_kernel_version}-generic"

            package { 'apparmor' : ensure => '2.7.102-0ubuntu3.10', notify => Reboot["after"], }
            ->
            package { $headers : ensure => present, notify => Reboot["after"], }
            ->
            package { $headers_generic : ensure => present, notify => Reboot["after"], }
            ->
            package { $image : ensure => present, notify => Reboot["after"], }
            ->
            reboot { 'after':
              subscribe       => Package[$image],
              apply => "immediately",
              message => "Rebooting for kernel upgrade",
              timeout => 0,
            }
        }
    } else {
        #TODO for other flavours do nothing
    }

}
#end of upgrade-kernel
