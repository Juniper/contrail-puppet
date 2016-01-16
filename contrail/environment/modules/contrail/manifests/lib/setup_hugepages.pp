define contrail::lib::setup_hugepages(
    $contrail_logoutput = false,
    $enable_dpdk = $::contrail::params::enable_dpdk,
    $contrail_dpdk_huge_page_factor = $::contrail::params::huge_pages,
) {

  if ($enable_dpdk == true) {


    if ($contrail_reserv_pg == "") {
      $contrail_reserve_pages = 0
    } else {
      $contrail_reserve_pages = $contrail_reserv_pg
    }



    $requested = ((($contrail_mem_sz * ($contrail_dpdk_huge_page_factor + 0)) /100)/$contrail_pg_sz)
    $mount_line='hugetlbfs    /hugepages    hugetlbfs defaults      0       0'

    if ($requested > $contrail_reserve_pages) {
      $requested_str = "${requested}"
      sysctl::value { 'vm.nr_hugepages':
        value => $requested_str
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
    ->
    exec { 'mount_hugepages' :
      command   => 'mount -t hugetlbfs hugetlbfs /hugepages',
                provider  => 'shell',
                logoutput => $contrail_logoutput
    }
  } else {

  } 
} 
