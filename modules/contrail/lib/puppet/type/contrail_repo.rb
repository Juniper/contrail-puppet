Puppet::Type.newtype(:contrail_repo) do

  ensurable
  validate do
    #fail('ensure is a required parameter') if self[:ensure].nil?
    fail('Repo host/ip required when ensure is present') if self[:ensure] == :present and self[:repo_host].nil?
  end
  newparam(:name, :namevar =>true) do
  end

  newparam(:repo_host) do
    #validate do |value|
      #fail("Invalid repo Host/IP #{value}") unless value == '1.1.1.1'
    #end
    #munge do |value|
      #"deb http:///world/#{value}/bye/bye contrail main"
    #end
  end
end
