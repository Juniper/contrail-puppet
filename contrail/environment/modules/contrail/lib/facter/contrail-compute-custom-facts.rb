require 'facter'

Facter.add(:ipv4_reserved_ports) do
    setcode do
        Facter::Util::Resolution.exec('sysctl -a | grep net.ipv4.ip_local_reserved_ports | awk -F= \'{print $2}\'')
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
