# == Class: contrail::database
#
# This class is used to configure software and services required
# to run cassdandra database module used by contrail software suit.
#
# === Parameters:
#
# [*host_control_ip*]
#     IP address of the server where database module is being installed.
#     if server has separate interfaces for management and control, this
#     parameter should provide control interface IP address.
#
# [*config_ip*]
#     IP address of the server where config module of contrail cluster is
#     configured. In multiple config nodes setup, specify address of first
#     config node. If HA is configured (internal VIP not null), the actual
#     address that gets used is internal VIP.
#
# [*database_ip_list*]
#     List of control interface IPs of all the servers running database role.
#     This is used to derive following variables used by this module.
#     - cassandra_seeds : In case of single DB node, set to database_ip_list
#       else, set to database_ip_list, minus current node.
#     - zookeeper_ip_list : set to database_ip_list (Also provided as separate
#       parameter in case user would like to separate zookeeper from DB.
#     - database_index - Index of this DB node in list of database_ip_list (1-based).
#
# [*internal_vip*]
#     Virtual IP for openstack nodes in case of HA configuration.
#     (Optional) - Defaults to "", meaning no HA configuration.
#
# [*zookeeper_ip_list*]
#     list of control interface IPs of all nodes running zookeeper service.
#     (optional) - Specify only if zookeeper server list is different from DB server
#                  list. Currently supported for same list. Default database_ip_list.
#
# [*database_initial_token*]
#     Token to be used for database seeds.
#     (optional) - Defaults to 0.
#
# [*database_dir*]
#     Directory to be used for database data files.
#     (optional) - Defaults to "/var/lib/cassandra".
#
# [*analytics_data_dir*]
#     Directory to be used for analytics data files. Used when
#     analytics data to be kept in a separate partition with
#     link created from database data dir to the analytics partition dir
#     (optional) - Defaults to "".
#
# [*ssd_data_dir*]
#     Directory to be used for ssd data files (commit logs).
#     (optional) - Defaults to "".
#
# [*contrail_logoutput*]
#     Variable to specify if output of exec commands is to be logged or not.
#     Values are true, false or on_failure
#     (optional) - Defaults to false
#
# [*database_minimum_diskGB*]
#     Minimum disk space needed in GB for database.
#     (optional) - Defaults to 256
#
class contrail::database (
) {
    anchor {'contrail::database::start': } ->
    contrail::lib::report_status { 'database_started': } ->
    class { '::contrail::database::install': } ->
    class { '::contrail::database::config': } ~>
    class { '::contrail::database::service': } ->
    contrail::lib::report_status { 'database_completed': }
    anchor {'contrail::database::end': }
}
