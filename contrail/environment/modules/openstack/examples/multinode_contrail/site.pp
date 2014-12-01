class{
    '::openstack::config::contrail':
}

$contrail_hc_interval = 20
$contrail_use_certs = $::openstack::config::contrail::use_certs
$contrail_cfgm_number = $::openstack::config::contrail::cfgm_number
$contrail_uuid = $::openstack::config::contrail::uuid
$contrail_openstack_index = $::openstack::config::contrail::openstack_index
$contrail_api_nworkers = $::openstack::config::contrail::api_nworkers
$contrail_database_initial_token = $::openstack::config::contrail::database_initial_token
$contrail_bgp_params = $::openstack::config::contrail::bgp_params
$contrail_supervisorctl_lines = $::openstack::config::contrail::supervisorctl_lines
$contrail_encap_priority = $::openstack::config::contrail::encap_priority
$contrail_rabbit_user = $::openstack::config::contrail::rabbit_user
$contrail_multi_tenancy = $::openstack::config::contrail::multi_tenancy
$contrail_router_asn = $::openstack::config::contrail::router_asn
$contrail_database_dir = $::openstack::config::contrail::database_dir
$contrail_haproxy = $::openstack::config::contrail::haproxy
$contrail_rmp_is_master = $::openstack::config::contrail::rmq_is_master
$contrail_zk_ip_port = $::openstack::config::contrail::zk_ip_port
$contrail_cfgm_index = $::openstack::config::contrail::cfgm_index
$contrail_storage_num_osd = $::openstack::config::contrail::storage_num_osd
$contrail_redis_ip = $::openstack::config::contrail::redis_ip
$contrail_config_ip = $::openstack::config::contrail::config_ip
$contrail_collector_ip = $::openstack::config::contrail::collector_ip
$contrail_cassandra_ip_port = '9160'
$contrail_analytics_data_ttl = 600
$contrail_control_name_list = $::openstack::config::contrail::control_name_list
$contrail_rmq_master = $::openstack::config::contrail::rmq_master
$contrail_ip_list = $::openstack::config::contrail::cassandra_ip_list
$contrail_control_ip_list = $::openstack::config::contrail::control_ip_list
$contrail_cassandra_ip_list = $::openstack::config::contrail::cassandra_ip_list
$contrail_cassandra_seeds = $::openstack::config::contrail::cassandra_seeds
$contrail_compute_ip = $::openstack::config::contrail::compute_ip
$contrail_zookeeper_ip_list = $::openstack::config::contrail::zookeeper_ip_list
$contrail_amqp_server_ip = $::openstack::config::contrail::amqp_server_ip
$contrail_openstack_root_passwd = $::openstack::config::contrail::openstack_root_passwd
$ks_admin_user = $::openstack::config::contrail::ks_admin_user
#$ks_admin_tenant = $::openstack::config::contrail::ks_admin_tenant
$ks_admin_tenant = "admin"
$ks_auth_protocol = 'http'
$ks_auth_port = '35357'
$contrail_ks_insecure_flag = False
$contrail_memcached_opt = ""
$contrail_repo_name = $::openstack::config::contrail::repo_name
$contrail_repo_ip = $::openstack::config::contrail::repo_ip
$contrail_host_roles = $::openstack::config::contrail::host_roles


$contrail_vm_ip = ""
$contrail_vm_username = $::openstck::config::contrail::vm_username
$contrail_vm_passwd = $::openstck::config::contrail::vm_passwd
$contrail_vswitch = $::openstck::config::contrail::vswitch
$contrail_non_mgmt_gw = "192.168.11.1"

$region = "openstack"
#$controller_address_api = "192.168.11.4"
#$controller_address_management = "192.168.11.4"
$contrail_discovery_ip = "192.168.11.200"

#Test configuration for HA
$controller_address_api = "192.168.11.200"
$controller_address_management = "192.168.11.200"

$keystone_admin_token = "sosp-lyl"
$keystone_admin_password = "fyby-tet"
$keystone_nova_password = "quuk-paj"
$contrail_num_controls = "1"
$contrail_cidr = "/24"

$host_ip = $::ipaddress_eth1
$contrail_config_user = $host_ip
$contrail_config_passwd = $host_ip
$contrail_cfgm_ip = $host_ip
$contrail_non_mgmt_ip = $host_ip
$contrail_database_ip = $host_ip

$internal_vip = $controller_address_api
$external_vip = $controller_address_api
$contrail_internal_vip = $controller_address_api

$compute_ip_list = ['192.168.11.7']
$config_ip_list = ['192.168.11.4', '192.168.11.5', '192.168.11.6']
$openstack_ip_list_control = ['192.168.11.4', '192.168.11.5', '192.168.11.6']
$openstack_ip_list = ['192.168.11.4', '192.168.11.5', '192.168.11.6', '192.168.11.7']
$openstack_user_list = ['root', 'root', 'root', 'root']
$openstack_password_list = ['c0ntrail123', 'c0ntrail123', 'c0ntrail123', 'c0ntrail123']
$root_password='c0ntrail123'
$mysql_root_password = 'spam-gak'
$os_master = '192.168.11.4'


$discovery_ip = $contrail_internal_vip
$vrrp_interface = 'eth1'

node 'puppet' {
  include ::ntp
}

node 'control.localdomain' {
  $vrrp_state = "MASTER"
  $contrail_rmq_is_master = true
  $contrail_openstack_index = 1
  $sync_db = true
  include ::openstack::role::contrail::controller
  class { '::openstack::profile::provision':
      before => Service['glance-api']
  }
  class {'::openstack::profile::contrail::provision':
      stage => 'last'
  }
#class { '::openstack::setup::cirros':
#      stage => 'last'
#  }
}

node 'control2.localdomain' {
  $contrail_database_index = "2"
  $contrail_cfgm_index = "2"
  $contrail_openstack_index = 2
  $contrail_rmq_is_master = false
  $vrrp_state = "BACKUP"
  $sync_db = false
  include ::openstack::role::contrail::controller
}

node 'control3.localdomain' {
  $contrail_database_index = "3"
  $contrail_cfgm_index = "3"
  $contrail_openstack_index = 3
  $vrrp_state = "BACKUP"
  $contrail_rmq_is_master = false
  $sync_db = false
  include ::openstack::role::contrail::controller
}

node 'compute.localdomain' {
  include ::openstack::role::contrail::compute
}

#TODO define contrail related node

node 'tempest.localdomain' {
  include ::openstack::role::tempest
}

