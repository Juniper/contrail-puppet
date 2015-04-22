# This resource is used if operating system is centos. In other cases, it does not do anything.
# The resource checks if contrail-rename-interface package is installed or not (which renames
# interfaces in centos to known names. After installing, it reboots the box. Once rename and reboot
# is done, subsequent executions of this resource do not do anything.
define contrail::lib::contrail-rename-interface {

    if (inline_template('<%= operatingsystem.downcase %>') == "centos") {
	# Ensure contrail-interface-name package is installed, which renames the interface
	package { 'contrail-interface-name' : ensure => latest,}

	# Now reboot the system
	exec { "reboot-server" :
	    command   => "echo reboot-server-1 >> /etc/contrail/contrail_compute_exec.out && reboot",
	    require => [ Package["contrail-interface-name"] ],
	    unless => ["grep -qx reboot-server-1 /etc/contrail/contrail_compute_exec.out"],
	    provider => "shell"
	}
    }
}

