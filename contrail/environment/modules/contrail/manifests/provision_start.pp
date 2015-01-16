class contrail::provision_start(
    $state = undef
)
{
    contrail::lib::report_status { $state: state => $state }

}



