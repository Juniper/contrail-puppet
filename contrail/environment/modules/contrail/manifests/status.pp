class contrail::status (
    $state = undef
)
{
    contrail::lib::report_status { $state: state => $state }

}



