#build_vcpu_pin_list.rb

module Puppet::Parser::Functions
    newfunction(:build_vcpu_pin_list, :type => :rvalue,
                :doc => "Given a hexadecimal number, convert it to comma separated list of cores for vcpu pin list") do |args|
        core_mask = args[0]
        if core_mask[0..1].downcase != "0x"
            raise Puppet::ParseError, "Invalid core_mask value, must be specified as hex in 0xabcd format : #{core_mask}"
        end
        pin_list = ""
        core_mask_val = core_mask[2..-1].to_i(16)
        num_cores_fact =  lookupvar('processorcount')
        for i in 0...num_cores_fact
            if (core_mask_val & (1 << i) == 0)
                pin_list = [pin_list, i.to_s].reject(&:empty?).join(',')
            end
        end
        pin_list
    end
end
