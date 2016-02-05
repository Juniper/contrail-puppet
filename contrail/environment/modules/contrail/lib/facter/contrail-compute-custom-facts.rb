require 'facter'

Facter.add(:ipv4_reserved_ports) do
    setcode do
        Facter::Util::Resolution.exec('sysctl -a | grep net.ipv4.ip_local_reserved_ports | awk -F= \'{print $2}\' | tr -d \' \'')
    end
end
Facter.add(:contrail_gateway) do
    setcode do
        Facter::Util::Resolution.exec(File.join(File.dirname(__FILE__), 'gateway.sh'))
    end
end

Facter.add(:contrail_interface) do
    setcode do
        Facter::Util::Resolution.exec(File.join(File.dirname(__FILE__), 'interface.sh'))
    end
end

Facter.add(:contrail_interface_rename_done) do
    setcode do
        Facter::Util::Resolution.exec(File.join(File.dirname(__FILE__), 'is_intf_renamed.sh'))
    end
end

Facter.add(:openstack_release) do
    setcode do
        Facter::Util::Resolution.exec(File.join(File.dirname(__FILE__), 'openstack_release.sh'))
    end
end
Facter.add(:openstack_version) do
    setcode do
        Facter::Util::Resolution.exec('/usr/bin/nova-manage version')
    end
end
Facter.add(:contrail_version) do
    setcode do
        Facter::Util::Resolution.exec('dpkg -l contrail-install-packages | grep contrail-install-packages | awk \'{ printf $3}\'')
    end
end
Facter.add(:conductor_idx) do
    setcode do
        Facter::Util::Resolution.exec(File.join(File.dirname(__FILE__), 'nova_idx.sh nova-conductor'))
    end
end
Facter.add(:console_idx) do
    setcode do
        Facter::Util::Resolution.exec(File.join(File.dirname(__FILE__), 'nova_idx.sh nova-console'))
    end
end
Facter.add(:consoleauth_idx) do
    setcode do
        Facter::Util::Resolution.exec(File.join(File.dirname(__FILE__), 'nova_idx.sh nova-consoleauth'))
    end
end
Facter.add(:scheduler_idx) do
    setcode do
        Facter::Util::Resolution.exec(File.join(File.dirname(__FILE__), 'nova_idx.sh nova-scheduler'))
    end
end
Facter.add(:python_dist) do
    setcode do
        Facter::Util::Resolution.exec('python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"')
    end
end
Facter.add(:contrail_mem_sz) do
    setcode do
        Facter::Util::Resolution.exec(File.join(File.dirname(__FILE__), 'mem_size.sh'))
    end
end
Facter.add(:contrail_pg_sz) do
    setcode do
        Facter::Util::Resolution.exec(File.join(File.dirname(__FILE__), 'pg_sz.sh'))
    end
end
Facter.add(:contrail_reserv_pg) do
    setcode do
        Facter::Util::Resolution.exec(File.join(File.dirname(__FILE__), 'reserv_pg.sh'))
    end
end
Facter.add(:contrail_vm_nr_hugepages) do
    setcode do
        Facter::Util::Resolution.exec('sysctl -n vm.max_map_count')
    end
end
Facter.add(:contrail_dpdk_bind_if) do
    setcode do
        Facter::Util::Resolution.exec('ifconfig vhost > /dev/null && grep "^physical_interface=" /etc/contrail/contrail-vrouter-agent.conf | awk -F= \'{print $2}\'')
    end
end
Facter.add(:contrail_dpdk_bind_pci_address) do
    setcode do
        Facter::Util::Resolution.exec('ifconfig vhost > /dev/null && grep "^physical_interface_address=" /etc/contrail/contrail-vrouter-agent.conf | awk -F= \'{print $2}\'')
    end
end

