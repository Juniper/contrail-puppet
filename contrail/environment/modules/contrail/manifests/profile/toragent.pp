class contrail::profile::toragent(
    $enable_toragent = $::contrail::params::enable_toragent
)
{
    if ($enable_toragent)  {
        contain ::contrail::toragent
    }
}
