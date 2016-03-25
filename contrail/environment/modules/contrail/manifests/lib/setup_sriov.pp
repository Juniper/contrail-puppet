define contrail::lib::setup_sriov(
    $intf_name,
    $num_of_vfs,
    $physnet_list,
) {
       $line = "echo ${num_of_vfs} > /sys/class/net/${intf_name}/device/sriov_numvfs"
       exec { "setup_rc_local_${title}":
           command  => "sed -i '/exit 0/i ${line}' /etc/rc.local",
           provider => shell,
           logoutput => true,
       }



   contrail::lib::setup_passthrough_white_list{ $physnet_list: 
                               dev_name => $intf_name }
   

}
