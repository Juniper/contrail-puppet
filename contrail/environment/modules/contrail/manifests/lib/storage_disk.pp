#TODO: Document

define contrail::lib::storage_disk(
  $host_name = $::hostname,
  $contrail_logoutput = 'true'
  #$contrail_logoutput = $::contrail::params::contrail_logoutput
) {
  $storage_disk_details = $name
  notice ("PROCESSING => $storage_disk_details")
  $disk_details = split($storage_disk_details, ':')
  $disk_detail_count = inline_template('<%= @disk_details.length %>')
  #$disk_detail_count = size($disk_details)

  notice ("count is  $disk_detail_count")
  if ($disk_detail_count == 1 ) {
    notice($disk_details[0])
    $ready_disk_name = $disk_details[0]
  } elsif ($disk_detail_count == 2 ) {
    # we could have '/dev/sda:Pool' or '/dev/sda:/sdb'
    notice("disks-details => ", $disk_details[0],$disk_details[1])
    if ($disk_details[1]  =~ /^P.*/ ) {
      notice("I want to configure POOL")
      $ready_disk_name = $disk_details[0]
    } elsif ($disk_details[1]  =~ /^\/.*/ ) {
      notice("I want to configure Journal")
      #$ready_disk_name = join($disk_details[0],':', $disk_details[1])
      $ready_disk_name = "${disk_details[0]}:${disk_details[1]}"
    } else {
      warning ("WRONG INPUT:Pool name must start with P and journal should start with '/'")
      $ready_disk_name = $disk_details[0]
    }
  } elsif ($disk_detail_count == 3 ) {
    # we could have '/dev/sda:/dev/sdc/Pool_c'
    notice("disks-details => ", $disk_details[0],$disk_details[1], $disk_details[2] )
    $ready_disk_name = "${disk_details[0]}:${disk_details[1]}"
    if ($disk_details[2]  =~ /^P.*/ ) {
      notice("I want to configure POOL")
    } else {
      warning ("WRONG INPUT:Pool name must start with P")
    }
  } else {
     fail("more than 4 items")
  }

  notice ("PREPARE: $ready_disk_name")

  contrail::lib::prepare_disk{ $ready_disk_name: }
  ->
  ceph::osd { $ready_disk_name:
    require => Contrail::Lib::Prepare_disk[$ready_disk_name]
  }
}
#contrail::lib::storage_disk {'/dev/sda':}
#contrail::lib::storage_disk {'/dev/sdb:/dev/sdc':}
#contrail::lib::storage_disk {'/dev/sdb:Pool_a':}
#contrail::lib::storage_disk {'/dev/sdb:/dev/sdc:Pool_a':}
#contrail::lib::storage_disk {'/dev/sdb:Bool_a':}
#contrail::lib::storage_disk {'/dev/sdb:/dev/sdc:Bool_a':}
#contrail::lib::storage_disk {'/dev/sdb:/dev/sdc:Pool_a:hello':}
