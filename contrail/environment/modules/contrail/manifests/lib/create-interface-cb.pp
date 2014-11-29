define contrail::lib::create-interface-cb(
    $contrail_package_id
) {
    exec { "contrail-interface-cb" :
        command => "curl -H \"Content-Type: application/json\" -d '{\"package_image_id\":\"$contrail_package_id\",\"id\":\"$hostname\"}' http://$serverip:9001/interface_created && echo create-interface-cb >> /etc/contrail/contrail_common_exec.out",
        provider => shell,
        logoutput => "true"
    }
}
