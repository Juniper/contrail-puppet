## TODO: Change function name to avoid '-' hyphen in function name
## TODO: take care of sed comamnds in update_interface_file1
#
define contrail::lib::contrail_upgrade(
    $contrail_upgrade = false,
    $contrail_logoutput = false,
    $upgrade_needed = $::contrail::params::upgrade_needed,
    ) {

    if ((($contrail_upgrade == true) or ($upgrade_needed == 1)) and ($::operatingsystem == "Ubuntu")) {
        Notify['contrail_upgrade_notify_2']->Notify['contrail_upgrade_notify_4']
        notify {'contrail_upgrade_notify_4': name => '*** UPGRADING ***';} ->
        exec { "update_interface_file1":
            command   => "sed -i 's/^\"//g' /etc/network/interfaces",
            provider  => shell,
            logoutput => $contrail_logoutput
        } ->
        exec { 'update_interface_file2':
            command   => "sed -i 's/\"//g' /etc/network/interfaces",
            provider  => shell,
            logoutput => $contrail_logoutput
        } ->
        exec { 'storage_lm_boot_flag' :
          command   => "/bin/true  # comment to satisfy puppet syntax requirements
set -x
ifconfig livemnfsvgw
RETVAL=\$?
if [ \${RETVAL} -eq 0 ]
then
    openstack-config --set /etc/nova/nova.conf DEFAULT resume_guests_state_on_host_boot True
fi
#ensure we return success always
exit 0
",
          logoutput => $contrail_logoutput,
        } ->
        exec { 'clear_out_files' :
            command   => 'rm -f /etc/contrail/contrail*.out && rm -f /opt/contrail/contrail_packages/exec-contrail-setup-sh.out && echo reset_provision_3_0 >> /etc/contrail/contrail_common_exec.out',
            unless    => 'grep -qx reset_provision_3_0  /etc/contrail/contrail_common_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput
        }
    }
}
