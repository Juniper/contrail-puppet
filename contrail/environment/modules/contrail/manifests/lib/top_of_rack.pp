define contrail::lib::top_of_rack(
    $tunnel_ip_address,
    $ovs_port,
    $http_server_port,
    $ip_address,
    $id,
    $vendor_name,
    $ovs_protocol,
    $type,
    $switch_name,
    $discovery_ip_to_use,
    $contrail_tsn_ip,
    $contrail_tsn_hostname,
    $contrail_openstack_ip,
    $contrail_config_ip,
    $keystone_admin_user,
    $keystone_admin_password,
    $keystone_admin_tenant) {

    notify { "**** $module_name - $name =>  $tunnel_ip_address, $ovs_port, $http_server_port , $ip_address, $id, $vendor_name, $ovs_protocol, $ovs_protocol, $switch_name": ; }

    file { "tor-agent-config-$id" :
        path => "/etc/contrail/contrail-tor-agent-$id.conf",
        content => template("$module_name/contrail_tor_agent_config.erb"),
    } 
    -> 
    file { "tor-agent-ini-$id" :
        path => "/etc/contrail/supervisord_vrouter_files/contrail-tor-agent-$id.ini",
        content => template("$module_name/contrail_tor_agent.ini.erb"),
    } 
    -> 
    file { "tor-agent-svc-$id" :
        path => "/etc/init.d/contrail-tor-agent-$id",
        mode => 0755,
        content => template("$module_name/contrail_tor_agent.svc.erb"),
    }
    ->
    service { "contrail-tor-agent-$id" :
       enable => true,
       subscribe => [ File["tor-agent-config-$id"] ],
       ensure => running,
    }
    ->
    exec { "register-tor-$id" :
       command => "python /opt/contrail/utils/provision_physical_device.py \
                   --device_name $switch_name --vendor_name  $vendor_name\
                   --device_mgmt_ip $ip_address --device_tunnel_ip $tunnel_ip_address \
                   --device_tor_agent $hostname-$id --device_tsn $contrail_tsn_hostname \
                   --api_server_ip $contrail_config_ip  --openstack_ip $contrail_openstack_ip  \
                   --oper add  --admin_user $keystone_admin_user \
                   --admin_password $keystone_admin_password \
                   --admin_tenant_name $keystone_admin_tenant",
     provider => shell
    }


  #if $id == "2" {
	    #file { "contrail-storage-exit-file":
	        #path => "/etc/contrail/contrail_setup_utils/config-storage-exit.sh",
	        #ensure  => present,
	        #mode => 0755,
	        #owner => root,
	        #group => root,
            #content => "exit 1",
           #}
           #->
          #exec { "contrail-tor-exit-$name" :
	     #command => "/etc/contrail/contrail_setup_utils/config-storage-exit.sh",
	     #provider => shell,
          #}
  #}

}
