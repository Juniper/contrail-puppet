# == Class: contrail::profile::keepalived
# The puppet module to set up keepalived for contrail
#
# === Parameters:
#
# [*enable_module*]
#     Flag to indicate if profile is enabled. If true, the module is invoked.
#     (optional) - Defaults to true.
#
class contrail::profile::keepalived (
    $enable_module = $::contrail::params::enable_keepalived,
    $host_roles = $::contrail::params::host_roles
) {
    if ($enable_module and ('config' in $host_roles or 'openstack' in $host_roles)) {
        contrail::lib::report_status { 'keepalived_started': state => 'keepalived_started' } ->
        Class['::contrail::keepalived'] ->
        contrail::lib::report_status { 'keepalived_completed': state => 'keepalived_completed' }
        contain ::contrail::keepalived
    } elsif (((!('config' in $host_roles)) and ($contrail_roles['config'] == true)) or
             ((!('openstack' in $host_roles)) and ($contrail_roles['openstack'] == true)) 
            ) {
        contrail::lib::report_status { 'uinstall_keepalived_started': state => 'uninstall_keepalived_started' } ->
        Class['::contrail::uninstall_keepalived'] ->
        contrail::lib::report_status { 'uninstall_keepalived_completed': state => 'uninstall_keepalived_completed' }
        contain ::contrail::uninstall_keepalived
    }
}
