define contrail::lib::setup_passthrough_white_list(
    $dev_name,
) {
   $physnet = $title

   notify { "phys_nets_${title} = ${physnet}":; }
   notify { "dev_name_${title} = ${dev_name}":; }
   $wl = "{ \"devname\": \"${dev_name}\", \"physical_network\": \"${physnet}\"}"
   $pci_passthrough_whitelist_line = "pci_passthrough_whitelist = ${wl}"
   notify { "wl_${title}=${wl}":; }
   notify { "pci_passthrough_whitellist_line_${title}=${pci_passthrough_whitelist_line}":; }
   exec { "config_pci_whitelist_${title}":
      command => "sed  -i '/\[DEFAULT\]/a ${pci_passthrough_whitelist_line} ' /etc/nova/nova.conf",
      provider => shell,
      logoutput => true
   }


/*
   file_line { "config_pci_whitelist_${title}":
      path => '/etc/nova/nova.conf',
      line => "pci_passthrough_whitelist = ${wl}"
   }
  #cannot use openstack-config as multi-valued option is not supported
  #Also cannot use nova_config resourse as it is seen as a re-declaration by puppet
   exec { "config_pci_whitelist_${title}":
      command => "openstack-config --set /etc/nova/nova.conf DEFAULT pci_passthrough_whitelist ${wl}",
      provider => shell,
      logoutput => true
   }

   $nova_pci_passthrough_whitelist_params = {
     'pci_passthrough_whitelist' => { value => '{ "devname": $dev_name, "physical_network": $physnet}'}
   }

   create_resources(nova_config, $nova_pci_passthrough_whitelist_params, {})
*/
}
