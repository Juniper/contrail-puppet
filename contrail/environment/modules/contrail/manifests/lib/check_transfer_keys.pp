define contrail::lib::check_transfer_keys {
    $host_ip = $name
    exec { "check_transfer_keys_on_${host_ip}" :
        command => "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$host_ip \'cat /etc/contrail/contrail_openstack_exec.out | grep exec-transfer-keys\' && echo check_transfer_keys_on_${host_ip} >> /etc/contrail/contrail_openstack_exec.out",
        unless  => " grep -qx check_transfer_keys_on_${host_ip} /etc/contrail/contrail_openstack_exec.out",
        provider => shell,
        logoutput => $contrail_logoutput
    }
}
#end of check_transfer_keys
