## TODO: document function
define contrail::lib::post_openstack(
    $host_control_ip,
    $openstack_ip_list,
    $internal_vip,
    $password  = $::contrail::params::os_mysql_service_password,
    $contrail_logoutput = false,
    $keystone_ip = $::contrail::params::keystone_ip,
    $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
) {
  if ($host_control_ip in $openstack_ip_list) {
    #Make ha-mon start later
    if($internal_vip != '') {
        exec { 'ha-mon-restart':
            command   => 'service contrail-hamon restart && echo contrail-ha-mon >> /etc/contrail/contrail_openstack_exec.out',
            provider  => shell,
            logoutput => $contrail_logoutput,
        }
      # Set mysql cpnnection string at the end
      # as setting before will result in provision failure.
      # Openstack is setup before galera is setup.
      # Intiailly mysql connection string is setup to internal_vip:3306,
      # making all mysql commands to land on vip node.
      # Later mysql needs to change to localip to support failover scenarios.
      # If mysql connection string is setup to local_ip while provisoning openstack.
      # openstack 2,3 provision will fail as db-sync is done only on 1,
      # and they dont find the tables.
      $keystone_database_credentials = join([$password, "@", $keystone_ip_to_use],'')
      $database_credentials = join([$password, "@", $host_control_ip],'')
      $keystone_db_conn = join(["mysql://keystone:",$keystone_database_credentials,"/keystone"],'')
      $cinder_db_conn = join(["mysql://cinder:",$database_credentials,"/cinder"],'')
      $glance_db_conn = join(["mysql://glance:",$database_credentials,"/glance"],'')
      $neutron_db_conn = join(["mysql://neutron:",$database_credentials,"/neutron"],'')
      $nova_db_conn = join(["mysql://nova:",$database_credentials,"/nova"],'')

      keystone_config {
        'DATABASE/connection'   : value => $keystone_db_conn;
        'SQL/connection'        : value => $keystone_db_conn;
      }
      cinder_config {
        'DATABASE/connection'   : value => $cinder_db_conn;
      }
      glance_registry_config {
        'DATABASE/connection'   : value => $glance_db_conn;
      }
      glance_api_config {
        'DATABASE/connection'   : value => $glance_db_conn;
      }
      neutron_config {
        'DATABASE/connection'   : value => $neutron_db_conn;
      }
      nova_config {
        'DATABASE/connection'   : value => $nova_db_conn;
      } -> Exec [ 'supervisor-openstack-restart']

    } elsif($keystone_ip != '') {
      # Temporary workaround because nova database_connection is getting removed for Central Keystone
      $database_credentials = join([$password, "@", $host_control_ip],'')
      $nova_db_conn = join(["mysql://nova:",$database_credentials,"/nova"],'')
      nova_config {
          'DATABASE/connection'   : value => $nova_db_conn;
      } -> Exec [ 'supervisor-openstack-restart']
    }

    if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
      $openstack_restart_command = "service openstack-nova-api restart && service openstack-nova-conductor restart && service openstack-nova-scheduler restart"
    } else {
      $openstack_restart_command = "service supervisor-openstack restart ; service nova-compute restart"
    }

    exec { 'supervisor-openstack-restart':
      command   => $openstack_restart_command,
      provider  => shell,
      logoutput => $contrail_logoutput,
    }
  }
}
#end of post-openstack
