class contrail::profile::tsn(
    $enable_tsn= $::contrail::params::enable_tsn
)
{
        notify {"*** profile tsn *** $enable_tsn":}
    if ($enable_tsn)  {
        notify {"*** profile tsn enabled ***":;}
        contain ::contrail::tsn
    }
}
