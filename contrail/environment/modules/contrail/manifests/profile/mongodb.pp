# == Class: contrail::profile::mongodb
# The puppet module to set up mongodb::server and mongodb::client on database node
#
#
class contrail::profile::mongodb {
      $controller_address_management = hiera(openstack::controller::address::management)
      $database_ip_list = $::contrail::params::database_ip_list
      $primary_db_ip = $::contrail::params::database_ip_list[0]
      # Mongo DB Replset members are primary_db + slave_members below - All database nodes
      $mongo_slave_ip_list_str = inline_template('<%= @database_ip_list.delete_if {|x| x == @primary_db_ip }.join(";") %>')
      $mongo_slave_ip_list = split($mongo_slave_ip_list_str, ';')
      notify { "contrail::profile::mongodb - mongo_slave_ip_list = $mongo_slave_ip_list":;}
      $ceilometer_mongo_password = hiera(openstack::ceilometer::mongo::password)
      $ceilometer_password = hiera(openstack::ceilometer::password)
      $ceilometer_meteringsecret = hiera(openstack::ceilometer::meteringsecret)
      $mongodb_bind_address = $contrail::params::host_non_mgmt_ip
      $port = ":27017"
      $contrail_logoutput = $::contrail::params::contrail_logoutput

      define add_rs_members ($primary_db_ip){
        # Mongo DB Add RS members
        exec { "exec_mongo_add_rs_member $name":
          command => "/usr/bin/mongo --host $primary_db_ip --quiet --eval \'rs.add(\"$name:27017\").ok\' && echo \"exec_mongo_add_rs_member $name\" >> /etc/contrail/contrail_database_exec.out",
          logoutput => $contrail_logoutput,
          returns => 0,
          unless  => "/bin/grep -qx \"exec_mongo_add_rs_member $name\" /etc/contrail/contrail_database_exec.out",
        }
      }

      class { '::mongodb::server':
            bind_ip => ['127.0.0.1', $mongodb_bind_address],
            replset => 'rs-ceilometer',
            master => true,
      }

      class { '::mongodb::client': }
      mongodb_database { 'ceilometer':
          ensure  => present,
          tries   => 20,
          require => Class['mongodb::server'],
      }


      if($mongodb_bind_address == $primary_db_ip){
        # Check Mongodb conection
        exec { "exec_mongo_connection":
            command => "/usr/bin/mongo --host $primary_db_ip --quiet --eval \'db = db.getSiblingDB(\"ceilometer\")\'",
            logoutput => $contrail_logoutput,
            returns => 0,
        }

        # Setup MongoDb replicaSet
        exec { "exec_mongo_create_replset":
            command => "/usr/bin/mongo --host $primary_db_ip --quiet --eval \'rs.initiate({_id:\"rs-ceilometer\", members:[{_id:0, host:\"$primary_db_ip:27017\"}]}).ok\' && echo exec_mongo_create_replset >> /etc/contrail/contrail_database_exec.out",
            logoutput => $contrail_logoutput,
            returns => 0,
            tries => 5,
            unless  => "/bin/grep -qx exec_mongo_create_replset /etc/contrail/contrail_database_exec.out",
            try_sleep => 15,
        }

        # Check Mongodb Primary is Master
        exec { "exec_mongo_check_master":
            command => "/usr/bin/mongo --host $primary_db_ip --quiet --eval \'db.isMaster().ismaster\'",
            logoutput => $contrail_logoutput,
            returns => 0,
        }

        add_rs_members {
          $mongo_slave_ip_list:
          primary_db_ip => $primary_db_ip,
        }

        # Verify Replica set status and members
        exec { "exec_verify_rs_status":
            command => "/usr/bin/mongo --host $primary_db_ip --quiet --eval \'rs.status().ok\'",
            logoutput => $contrail_logoutput,
            returns => 0,
        }

        # MongoDb check user ceilometer
        exec { "exec_check_user_ceilometer":
            command => "/usr/bin/mongo --host $primary_db_ip --quiet --eval \'db.system.users.find({user:\"ceilometer\"}).count()\'",
            logoutput => $contrail_logoutput,
            returns => 0,
            tries => 5,
            try_sleep => 15,
        }

        # Add MongoDb user ceilometer
        exec { "exec_add_user_ceilometer":
            command => "/usr/bin/mongo --host $primary_db_ip --quiet --eval \'db = db.getSiblingDB(\"ceilometer\"); db.addUser({user: \"ceilometer\", pwd: \"$ceilometer_mongo_password\", roles: [ \"readWrite\", \"dbAdmin\" ]})\' && echo exec_add_user_ceilometer >> /etc/contrail/contrail_database_exec.out",
            logoutput => $contrail_logoutput,
            returns => 0,
            tries => 5,
            try_sleep => 15,
            unless  => "/bin/grep -qx exec_add_user_ceilometer /etc/contrail/contrail_database_exec.out",
        }

      }

      notify { "contrail::profile::mongodb - mongodb_bind_address = $mongodb_bind_address":;}
      notify { "contrail::profile::mongodb - primary_db_ip = $primary_db_ip":;}

      Class['::mongodb::server'] -> Class['::mongodb::client']
}
