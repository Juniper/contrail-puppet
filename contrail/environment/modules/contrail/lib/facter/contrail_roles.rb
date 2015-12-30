require 'facter'

Facter.add(:contrail_roles) do
    setcode do
        contrail_roles = {}
    	roles_array = ["database", "openstack", "config", "control", "analytics", "webui", "vrouter"]

	roles_array.each do |role| 
            service_str = "service supervisor-" + role + " status"
            puts(service_str)
            is_service_running = system(service_str)
            if (is_service_running)
                contrail_roles[role] = true 
            else
                contrail_roles[role] = false
            end
        end
        openstack_status_str = "openstack-status | grep -e glance"
        is_openstack_enabled = system(openstack_status_str)
        if (is_openstack_enabled)
            contrail_roles["openstack"] = true
        else
            contrail_roles["openstack"] = false
        end

        contrail_roles 
    end
end
