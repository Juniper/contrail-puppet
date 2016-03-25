define contrail::lib::setup_sriov_wrapper(
    $intf_hash,
    $enable_dpdk,
) {

  if ($enablle_dpdk){
    $iommu_var = "PT"
  } else {
    $iommu_var = "on"
  }


  if (!empty($intf_hash)) {
    $intf_details = $intf_hash[$title]
      if ($intf_hash) {
	file_line { "set_grub_iommu_${title}":
	  path  => '/etc/default/grub',
	  line  => 'GRUB_CMDLINE_LINUX_DEFAULT="nomdmonddf nomdmonisw intel_iommu=${iommu_var}"',
	  match => '^GRUB_CMDLINE_LINUX_DEFAULT.*',
	}
/*
        ->
        exec { "setup_default":
          command => "echo '[DEFAULT]' >> /etc/nova/nova.conf",
          provider => shell,
          logoutput => true,
        }
*/

      }

    notify { "intf_hash_${title} = ${intf_hash}":; }
    notify { "title_${title} = ${title}":; }
    notify { "intf_details_${title} = ${intf_details}":; }
    contrail::lib::setup_sriov{$title :
      intf_name => $title,
		num_of_vfs => $intf_details['VF'],
		physnet_list => $intf_details['physnets']
    }

  }
}
