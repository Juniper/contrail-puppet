## TODO: document function
define contrail::lib::post_openstack(
    $host_control_ip,
    $openstack_ip_list,
    $internal_vip,
    $contrail_logoutput = false,
) {
  if ($host_control_ip in $openstack_ip_list) {
    #Make ha-mon start later
    if($internal_vip != '') {
        #Get the value for hiera and not from openstack::config
        #as with sequencing changes openstack modules is disabled after its
        #step is completed.

        $password = hiera(openstack::mysql::service_password)
        exec { 'ha-mon-restart':
            command   => 'service contrail-hamon restart && echo contrail-ha-mon >> /etc/contrail/contrail_openstack_exec.out',
            provider  => shell,
            before    => Exec['exec_start_supervisor_openstack'],
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
      $database_credentials = join([$password, "@", $host_control_ip],'')
      $keystone_db_conn = join(["mysql://keystone:",$database_credentials,"/keystone"],'')
      $cinder_db_conn = join(["mysql://cinder:",$database_credentials,"/cinder"],'')
      $glance_db_conn = join(["mysql://glance:",$database_credentials,"/glance"],'')
      $neutron_db_conn = join(["mysql://neutron:",$database_credentials,"/neutron"],'')

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
    }
  }
}
#end of post-openstack
