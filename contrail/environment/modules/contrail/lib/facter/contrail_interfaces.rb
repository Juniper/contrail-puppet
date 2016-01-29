require 'facter'

Facter.add(:contrail_interfaces) do
    setcode do
        contrail_interfaces = {}
        interface_list_str = %x[ifconfig -a | grep HWaddr | awk \'{ print $1 \'}]
        intf_list = interface_list_str.split("\n")

	intf_list.each do |intf|
            intf_detail = {}
            vlan_intf = %x[ip addr show #{intf} | head -1| cut -f2 -d':' | grep -o '@.*']
            if (vlan_intf != "")
                intf_detail["vlan"] = true
                intf_detail["parent"] = vlan_intf.delete("\n").delete('@')
            else
                intf_detail["vlan"] = false
#                pci_address = %x[udevadm info -a -p /sys/class/net/#{intf} | awk -F/ '/device.*eth/ {print $4}']
                pci_address = %x[/opt/contrail/bin/dpdk_nic_bind.py --status | grep #{intf} | cut -d' ' -f 1]
                intf_detail["pci_address"] = pci_address.delete("\n")
            end
            contrail_interfaces[intf] = intf_detail
        end
        contrail_interfaces
    end
end
