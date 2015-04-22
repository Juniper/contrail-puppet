# find_matching_interface.rb
# Function returns name of interface that has an IP address on the same subnet
# as the IP address provided as argument.

module Puppet::Parser::Functions
    newfunction(:get_device_name_by_mac, :type => :rvalue,
                :doc => "Given MAC address find interface name matching the MAC address") do |args|
        require 'ipaddr'
        retcon = ""
        requested_mac = args[0]
        interfaces_fact =  lookupvar('interfaces')
        interfaces = interfaces_fact.split(",")
        interfaces.each do |interface|
            intf_ip = lookupvar("ipaddress_#{interface}")
            intf_mask = lookupvar("netmask_#{interface}")
            intf_mac = lookupvar("macaddress_#{interface}")
            if intf_mac != nil
                if intf_mac == requested_mac && interface != "vhost0"  
                     retcon = interface
                end
            end
        end
        if retcon == ""
            raise Puppet::ParseError, "No matching interface found : #{requested_mac}"
        end
        retcon
    end
end
