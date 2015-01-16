class contrail::provision_complete(
    $state = undef
)
{
    contrail::lib::report_status { $state: state => $state }

}



