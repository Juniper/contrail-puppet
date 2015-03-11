define contrail::lib::prepare_disk(
    $ensure = 'present',
    $contrail_logoutput = false) {

    $disk_name = $name
    case $ensure {
        default : { err ("unknown ensure value ${ensure}") }
        present : {
	    exec { $disk_name:
                   command => "/etc/contrail/contrail_setup_utils/config-storage-disk-clean.sh $disk_name" ,
                   ## TODO: Commenting for now, 
                   #require => File["ceph-disk-clean-file"],
                   provider => shell,
                   logoutput => $contrail_logoutput
           }
        }
        absent : {
            ## TODO: doing nothing as of now, this will be required when 
            ## TODO: support of deleting of OSD is added
        }
    }
}
