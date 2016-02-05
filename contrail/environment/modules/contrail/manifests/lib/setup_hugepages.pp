define contrail::lib::setup_hugepages(
    $contrail_logoutput = false,
    $enable_dpdk = $::contrail::params::enable_dpdk,
    $contrail_dpdk_huge_page_factor = $::contrail::params::huge_pages,
) {

  if ($enable_dpdk == true) {


    if ($contrail_reserv_pg == "") {
      $contrail_reserve_pages = 0
    } else {
      $contrail_reserve_pages = ($contrail_reserv_pg + 0)
    }



    $requested = ((($contrail_mem_sz * ($contrail_dpdk_huge_page_factor + 0)) /100)/$contrail_pg_sz)
    $mount_line='hugetlbfs    /hugepages    hugetlbfs defaults      0       0'


    if ($requested > $contrail_reserve_pages) {
      $requested_str = "${requested}"
      sysctl::value { 'vm.nr_hugepages':
        value => $requested_str
      }
    }

    #set the vm.max_map_count
    if($contrail_vm_nr_hugepages == "") {
      $cur_contrail_vm_nr_hugepages = 0
    } else {
      $cur_contrail_vm_nr_hugepages = ($contrail_vm_nr_hugepages + 0)
    }
    $DPDK_HUGEPAGES_INIT_TIMES=2

    $current_huge_pages = max(($contrail_reserve_pages + 0), ($requested + 0))
    $requested_max_map_count = $DPDK_HUGEPAGES_INIT_TIMES * $current_huge_pages
    if ($requested_max_map_count > $cur_contrail_vm_nr_hugepages) {
      $req_map_str = "${requested_max_map_count}"
      sysctl::value { 'vm.max_map_count':
        value => $req_map_str
      }

    }


    #mount hugepages filesystem
    #Doesnt seem to work
    /*
       mount { '/hugepages':
       name =>
       ensure => mounted,
       type => hugetlbfs,
       device => "hugetlbfs",
       atboot => true,
       }
     */


    file_line { "add_mount_points_to_fstab":
      path  => '/etc/fstab',
            line  => $mount_line,
    }
    ->
    file { '/hugepages':
      ensure => 'directory',
    }

  } else {

  }
}
