# == Class: contrail::profile::mongodb
# The puppet module to set up mongodb::server and mongodb::client on database node
#
#
class contrail::profile::mongodb(
      $controller_address_management = $::contrail::params::controller_address_management,
      $database_ip_list          = $::contrail::params::openstack_ip_list,
      $primary_db_ip             = $::contrail::params::openstack_ip_list[0],
      $ceilometer_mongo_password = $::contrail::params::os_mongo_password,
      $ceilometer_password       = $::contrail::params::os_ceilometer_password,
      $ceilometer_meteringsecret = $::contrail::params::os_metering_secret,
      $mongodb_bind_address      = $::contrail::params::host_ip,
      $contrail_logoutput        = $::contrail::params::contrail_logoutput,
) {
      $mongo_slave_ip_list       = delete($database_ip_list, $primary_db_ip)

      class { '::mongodb::server':
            bind_ip => ['127.0.0.1', $mongodb_bind_address],
            replset => 'rs-ceilometer',
            master  => true,
      } ->
      class { '::mongodb::client': } ->
      mongodb_database { 'ceilometer':
          ensure  => present,
          tries   => 20,
          require => Class['mongodb::server'],
      }

      if($mongodb_bind_address == $primary_db_ip){
        Mongodb_database['ceilometer'] ->
        # Check Mongodb conection
        exec { 'exec_mongo_connection':
            command   => "/usr/bin/mongo --host ${primary_db_ip} --quiet --eval \'db = db.getSiblingDB(\"ceilometer\")\'",
            logoutput => $contrail_logoutput,
            returns   => 0,
        } ->
        # Setup MongoDb replicaSet
        exec { 'exec_mongo_create_replset':
            command   => "/usr/bin/mongo --host ${primary_db_ip} --quiet --eval \'rs.initiate({_id:\"rs-ceilometer\", members:[{_id:0, host:\"${primary_db_ip}:27017\"}]}).ok\' && echo exec_mongo_create_replset >> /etc/contrail/contrail_mongodb_exec.out",
            logoutput => $contrail_logoutput,
            returns   => 0,
            tries     => 5,
            unless    => '/bin/grep -qx exec_mongo_create_replset /etc/contrail/contrail_mongodb_exec.out',
            try_sleep => 15,
        } ->
        # Check Mongodb Primary is Master
        exec { 'exec_mongo_check_master':
            command   => "/usr/bin/mongo --host ${primary_db_ip} --quiet --eval \'db.isMaster().ismaster\'",
            logoutput => $contrail_logoutput,
            returns   => 0,
        } ->
        exec { "exec_mongo_add_rs_member ${mongo_slave_ip_list}":
          command   => "/usr/bin/mongo --host ${primary_db_ip} --quiet --eval \'rs.add(\"${mongo_slave_ip_list}:27017\").ok\' && echo \"exec_mongo_add_rs_member ${mongo_slave_ip_list}\" >> /etc/contrail/contrail_mongodb_exec.out",
          logoutput => $contrail_logoutput,
          returns   => 0,
          unless    => "/bin/grep -qx \"exec_mongo_add_rs_member ${mongo_slave_ip_list}\" /etc/contrail/contrail_mongodb_exec.out",
        } ->
        # Verify Replica set status and members
        exec { 'exec_verify_rs_status':
            command   => "/usr/bin/mongo --host ${primary_db_ip} --quiet --eval \'rs.status().ok\'",
            logoutput => $contrail_logoutput,
            returns   => 0,
        } ->
        # MongoDb check user ceilometer
        exec { 'exec_check_user_ceilometer':
            command   => "/usr/bin/mongo --host ${primary_db_ip} --quiet --eval \'db.system.users.find({user:\"ceilometer\"}).count()\'",
            logoutput => $contrail_logoutput,
            returns   => 0,
            tries     => 5,
            try_sleep => 15,
        } ->
        # Add MongoDb user ceilometer
        exec { 'exec_add_user_ceilometer':
            command   => "/usr/bin/mongo --host ${primary_db_ip} --quiet --eval \'db = db.getSiblingDB(\"ceilometer\"); db.addUser({user: \"ceilometer\", pwd: \"${ceilometer_mongo_password}\", roles: [ \"readWrite\", \"dbAdmin\" ]})\' && echo exec_add_user_ceilometer >> /etc/contrail/contrail_mongodb_exec.out",
            logoutput => $contrail_logoutput,
            returns   => 0,
            tries     => 5,
            try_sleep => 15,
            unless    => '/bin/grep -qx exec_add_user_ceilometer /etc/contrail/contrail_mongodb_exec.out',
        }
      }
}
