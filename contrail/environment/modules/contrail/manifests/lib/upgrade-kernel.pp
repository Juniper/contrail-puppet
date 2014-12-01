define contrail::lib::upgrade-kernel($contrail_kernel_version) {
    $headers = "linux-headers-${contrail_kernel_version}"
    $headers_generic = "linux-headers-${contrail_kernel_version}-generic"
    $image = "linux-image-${contrail_kernel_version}"
    package { 'apparmor' : ensure => '2.7.102-0ubuntu3.10',}
    ->
    package { $headers : ensure => present, }
    ->
    package { $headers_generic : ensure => present, }
    ->
    package { $image : ensure => present, }
    ->
    exec { "upgrade-kernel-reboot":
	command => "echo upgrade-kernel-reboot >> /etc/contrail/contrail_common_exec.out && reboot ",
	provider => shell,
	logoutput => "true",
    unless => ["grep -qx upgrade-kernel-reboot /etc/contrail/contrail_common_exec.out"]
    }
}
#end of upgrade-kernel
