# == Class: contrail::ha_config
#
# This class is used to configure software and services required
# to provide HA functionality of contrail/openstack cluster.
#
# === Parameters:
#
# [*host_control_ip*]
#     IP address of the server.
#     If server has separate interfaces for management and control, this
#     parameter should provide control interface IP address.
#
# [*openstack_ip_list*]
#     List of control IP addresses of all servers running openstack.
#     Current host also runs openstack. It's address it to be passed as
#     first element of the list.
#
# [*openstack_mgmt_ip_list*]
#     List of management IP addresses of all servers running openstack.
#     Current host also runs openstack. It's address it to be passed as
#     first element of the list.
#
# [*root_password*]
#     Root password of the server.
#
# [*mysql_root_password*]
#     Mysql Root password of the server.
#
# [*internal_vip*]
#     Virtual IP of this server used for providing HA functinality.
#     (optional) - Defaults to "".
#
# [*keystone_admin_token*]
#     Keystone admin token.
#     (optional) - Defaults to "c0ntrail123".
#
# [*keystone_ip*]
#     Key stone IP address, if keystone service is running on a node other
#     than openstack controller.
#     (optional) - Default "", meaning use same address as openstack controller.
#
class contrail::ha_config (
    $host_control_ip = $::contrail::params::host_ip,
    $openstack_ip_list = $::contrail::params::openstack_ip_list,
    $openstack_mgmt_ip_list = $::contrail::params::openstack_mgmt_ip_list_to_use,
    $root_password = $::contrail::params::root_password,
    $mysql_root_password = $::contrail::params::mysql_root_password,
    $internal_vip = $::contrail::params::internal_vip,
    $keystone_admin_token = $::contrail::params::keystone_admin_token,
    $keystone_ip = $::contrail::params::keystone_ip
) inherits ::contrail::params {
    # Main code for class
    if($internal_vip != '') {
        if ($operatingsystem == "Ubuntu") {
            $wsrep_conf='/etc/mysql/conf.d/wsrep.cnf'
        } else {
            $wsrep_conf='/etc/mysql/my.cnf'
        }

        if ($keystone_ip != "") {
            $keystone_ip_to_use = $keystone_ip
        }
        else {
            $keystone_ip_to_use = $internal_vip
        }

        $tmp_index = inline_template('<%= @openstack_mgmt_ip_list.index(@host_control_ip) %>')
        if ($tmp_index != nil) {
            $openstack_index = $tmp_index + 1
        }
        $os_master = $openstack_ip_list[0]

        $glance_path ="/var"

        $openstack_mgmt_ip_list_shell = inline_template('<%= @openstack_mgmt_ip_list.map{ |ip| "#{ip}" }.join(",") %>')
        $openstack_ip_list_shell = inline_template('<%= @openstack_ip_list.map{ |name2| "#{name2}" }.join(" ") %>')

        $contrail_exec_vnc_galera = "MYSQL_ROOT_PW=$mysql_root_password PASSWORD=$root_password ADMIN_TOKEN=$keystone_admin_token setup-vnc-galera --self_ip $host_control_ip --keystone_ip $keystone_ip_to_use --galera_ip_list $openstack_ip_list_shell --internal_vip $internal_vip --openstack_index $openstack_index && echo exec_vnc_galera >> /etc/contrail/contrail_openstack_exec.out"
        $contrail_exec_check_wsrep = "python check-wsrep-status.py $openstack_mgmt_ip_list_shell  && echo check-wsrep >> /etc/contrail/contrail_openstack_exec.out"
        $contrail_exec_setup_cmon_schema = "python setup-cmon-schema.py $os_master $host_control_ip $internal_vip  && echo exec_setup_cmon_schema >> /etc/contrail/contrail_openstack_exec.out"

        #########Chhandak-HA
        # GALERA
        package { 'contrail-openstack-ha':
            ensure  => present,
        }
        ->
        file { "/etc/contrail/mysql.token" :
            ensure  => present,
            mode =>    0400,
            group => root,
            content => "$mysql_root_password"
        }
        ->
        file { "/opt/contrail/bin/setup-vnc-galera" :
            ensure  => present,
            mode =>    0755,
            group => root,
        }
        ->
        exec { "exec_vnc_galera" :
            command => $contrail_exec_vnc_galera,
            cwd => "/opt/contrail/bin/",
            unless  => "grep -qx exec_vnc_galera /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            require => [ File["/opt/contrail/bin/setup-vnc-galera"] ],
            logoutput => 'true',
            tries => 3,
            try_sleep => 15,
        }
        if ($openstack_index == "1" ) {
            # Fix WSREP cluster address
            # Need check this from provisioned ha box
            exec { "fix_wsrep_cluster_address" :
                command => "sudo sed -ibak 's#wsrep_cluster_address=.*#wsrep_cluster_address=gcomm://$openstack_ip_list_wsrep#g' $wsrep_conf && echo exec_fix_wsrep_cluster_address >> /etc/contrail/contrail_openstack_exec.out",
                require =>  [package["contrail-openstack-ha"],
                             Exec['exec_vnc_galera']],
                onlyif => "test -f $wsrep_conf",
                unless  => "grep -qx exec_fix_wsrep_cluster_address /etc/contrail/contrail_openstack_exec.out",
                provider => shell,
                logoutput => 'true',
            }
        }
        # setup_cmon
        file { "/opt/contrail/bin/setup-cmon-schema.py" :
            ensure  => present,
            mode => 0755,
            group => root,
            source => "puppet:///modules/$module_name/setup-cmon-schema.py"
        }
        ->
        exec { "exec_setup_cmon_schema" :
            command => $contrail_exec_setup_cmon_schema,
            cwd => "/opt/contrail/bin/",
            unless  => "grep -qx exec_setup_cmon_schema /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            require => [ File["/opt/contrail/bin/setup-cmon-schema.py"] ],
            logoutput => 'true',
        }
        ->
        exec { "setup-cluster-monitor" :
            command => "service contrail-hamon restart && chkconfig contrail-hamon on  && echo setup-cluster-monitor >> /etc/contrail/contrail_openstack_exec.out ",
            unless  => "grep -qx setup-cluster-monitor  /etc/contrail/contrail_compute_exec.out",
            provider => shell,
            logoutput => "true",
            tries => 3,
            try_sleep => 15,
        }
        ->
        exec { "fix_xinetd_conf" :
            command => "sed -i -e 's#only_from = 0.0.0.0/0#only_from = $self_ip 127.0.0.1#' /etc/xinetd.d/contrail-mysqlprobe && service xinetd restart && chkconfig xinetd on && echo fix_xinetd_conf >> /etc/contrail/contrail_openstack_exec.out",
            unless  => "grep -qx fix_xinetd_conf  /etc/contrail/contrail_openstack_exec.out",
            provider => shell,
            logoutput => 'true',
        }
    }
}
