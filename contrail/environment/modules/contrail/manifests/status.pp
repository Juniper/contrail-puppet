class contrail::status (
    $state = undef,
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
)
{
    contrail::lib::report_status { $state:
        state => $state, 
        contrail_logoutput => $contrail_logoutput }

}



