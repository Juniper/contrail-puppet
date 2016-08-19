# find_matching_interface.rb
# Function returns name of interface that has an IP address on the same subnet
# as the IP address provided as argument.

module Puppet::Parser::Functions
    newfunction(:find_matching_interface, :type => :rvalue,
                :doc => "Given IP address find interface name matching the IP address on same subnet as the given address") do |args|
        require 'ipaddr'
        retcon = ""
        requested_ipaddr = args[0]
        interfaces_fact =  lookupvar('interfaces')
        interfaces = interfaces_fact.split(",")
        interfaces.each do |interface|
            intf_ip = lookupvar("ipaddress_#{interface}")
            intf_mask = lookupvar("netmask_#{interface}")
            if intf_ip != nil
                intf_subnet = IPAddr.new("#{intf_ip}/#{intf_mask}").to_s
                addr_subnet = IPAddr.new("#{requested_ipaddr}/#{intf_mask}").to_s
                if intf_subnet == addr_subnet
                     retcon = interface
                end
            end
        end
        if retcon == ""
            raise Puppet::ParseError, "No matching interface found : #{requested_ipaddr}"
        end
        retcon
    end
end
