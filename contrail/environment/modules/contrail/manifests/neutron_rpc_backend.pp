class contrail::neutron_rpc_backend(
    $contrail_logoutput = $::contrail::params::contrail_logoutput,
) {
    exec { 'neutron-conf-exec':
        command   => "sudo sed -i 's/rpc_backend\s*=\s*neutron.openstack.common.rpc.impl_qpid/#rpc_backend = neutron.openstack.common.rpc.impl_qpid/g' /etc/neutron/neutron.conf && echo neutron-conf-exec >> /etc/contrail/contrail_openstack_exec.out",
        onlyif    => 'test -f /etc/neutron/neutron.conf',
        unless    => 'grep -qx neutron-conf-exec /etc/contrail/contrail_openstack_exec.out',
        provider  => shell,
        logoutput => $contrail_logoutput
    }
}
