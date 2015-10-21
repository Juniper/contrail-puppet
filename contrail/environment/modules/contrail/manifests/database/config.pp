
class contrail::database::config (
  $host_control_ip = $::contrail::params::host_ip,
  $config_ip = $::contrail::params::config_ip_to_use,
  $database_ip_list = $::contrail::params::database_ip_list,
  $internal_vip = $::contrail::params::internal_vip,
  $zookeeper_ip_list = $::contrail::params::database_ip_list,
  $database_initial_token = $::contrail::params::database_initial_token,
  $database_dir = $::contrail::params::database_dir,
  $analytics_data_dir = $::contrail::params::analytics_data_dir,
  $ssd_data_dir = $::contrail::params::ssd_data_dir,
  $contrail_logoutput = $::contrail::params::contrail_logoutput,
  $database_minimum_diskGB = $::contrail::params::database_minimum_diskGB,
) {
    # Main Class code
    case $::operatingsystem {
        Ubuntu: {
            $contrail_cassandra_dir = '/etc/cassandra'
            file {'/etc/init/supervisord-contrail-database.override':
              ensure  => absent,
            }
        }
        Centos: {
            $contrail_cassandra_dir = '/etc/cassandra/conf'
        }
        Fedora: {
            $contrail_cassandra_dir = '/etc/cassandra/conf'
        }
        default: {
            $contrail_cassandra_dir = '/etc/cassandra/conf'
        }
    }

    # set database_index
    $tmp_index = inline_template('<%= @database_ip_list.index(@host_control_ip) %>')
    if ($tmp_index == nil) {
        fail("Host ${host_control_ip} not found in servers of database roles")
    }
    $database_index = $tmp_index + 1

    # set cassandra_seeds list
    if (size($::contrail::params::data_base_ip_list) > 1) {
        $cassandra_seeds = difference($database_ip_list, [$host_control_ip])
    }
    else {
        $cassandra_seeds = $database_ip_list
    }

    $zk_ip_list_for_shell = inline_template('<%= @zookeeper_ip_list.map{ |ip| "#{ip}" }.join(" ") %>')
    $contrail_zk_exec_cmd = "/bin/bash /etc/contrail/contrail_setup_utils/config-zk-files-setup.sh ${::operatingsystem} ${database_index} ${zk_ip_list_for_shell} && echo setup-config-zk-files-setup >> /etc/contrail/contrail-config-exec.out"

    # Debug - Print all variables
    notify { "Database - contrail cassandra dir is ${contrail_cassandra_dir}":; }
    notify { "Database - host_control_ip = ${host_control_ip}":;}
    notify { "Database - config_ip = ${config_ip}":;}
    notify { "Database - internal_vip = ${internal_vip}":;}
    notify { "Database - database_ip_list = ${database_ip_list}":;}
    notify { "Database - zookeeper_ip_list = ${zookeeper_ip_list}":;}
    notify { "Database - database_index = ${database_index}":;}
    notify { "Database - cassandra_seeds = ${cassandra_seeds}":;}
    if ($analytics_data_dir != '') {
        # Make dir ContrailAnalytics in cassandra database folder
        file { "${database_dir}/ContrailAnalytics":
            ensure  => link,
            target  => "${analytics_data_dir}/ContrailAnalytics",
            require => File[$database_dir],
            notify  => Service['supervisor-database'],
            owner   => cassandra,
            group   => cassandra,
        }
    }
    file { $database_dir :
        ensure  => directory,
        owner   => cassandra,
        group   => cassandra,
    }
    ->

    file { "${contrail_cassandra_dir}/cassandra.yaml" :
        ensure  => present,
        content => template("${module_name}/cassandra.yaml.erb"),
    }
    ->
    file { "${contrail_cassandra_dir}/cassandra-env.sh" :
        ensure  => present,
        require => [ Package['contrail-openstack-database'] ],
        content => template("${module_name}/cassandra-env.sh.erb"),
    }
    ->
    file { '/usr/share/kafka/config/server.properties':
        ensure  => present,
        content => template("${module_name}/kafka.server.properties.erb"),
    }
    ->
    file { '/usr/share/kafka/config/log4j.properties':
        ensure  => present,
        content => template("${module_name}/kafka.log4j.properties.erb"),
    }
    File['/usr/share/kafka/config/log4j.properties'] -> File['/etc/contrail/contrail_setup_utils/config-zk-files-setup.sh']
    # Below is temporary to work-around in Ubuntu as Service resource fails
    # as upstart is not correctly linked to /etc/init.d/service-name
    if ($::operatingsystem == 'Ubuntu') {
        file { '/etc/init.d/supervisord-contrail-database':
            ensure  => link,
            target  => '/lib/init/upstart-job',
            #require => File["${contrail_cassandra_dir}/cassandra-env.sh"],
            before  => Service['supervisor-database']
        }
        File['/etc/init.d/supervisord-contrail-database'] -> File['/etc/contrail/contrail_setup_utils/config-zk-files-setup.sh']
    }
    # set high session timeout to survive glance led disk activity
    file { '/etc/contrail/contrail_setup_utils/config-zk-files-setup.sh':
        ensure  => present,
        mode    => '0755',
        owner   => root,
        group   => root,
        source  => "puppet:///modules/${module_name}/config-zk-files-setup.sh"
    }
    ->
    notify { "contrail contrail_zk_exec_cmd is ${contrail_zk_exec_cmd}":; }
    ->
    exec { 'setup-config-zk-files-setup' :
        command   => $contrail_zk_exec_cmd,
        unless    => 'grep -qx setup-config-zk-files-setup /etc/contrail/contrail-config-exec.out',
        provider  => shell,
        logoutput => $contrail_logoutput
    }
    ->
    file { '/etc/contrail/contrail-database-nodemgr.conf' :
        ensure  => present,
        content => template("${module_name}/contrail-database-nodemgr.conf.erb"),
    }
    ->
    file { '/etc/contrail/database_nodemgr_param' :
        ensure  => present,
        content => template("${module_name}/database_nodemgr_param.erb"),
    }
}
