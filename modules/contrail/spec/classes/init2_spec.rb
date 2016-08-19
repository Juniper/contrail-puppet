require 'spec_helper'
require 'hiera'
require 'pp'


#hiera_file = 'spec/fixtures/hiera/hiera.yaml'   # <- required to find hiera configuration file

describe 'contrail::common' do
  context 'The following classes should be present in the catalog' do
    #let (:hiera_config) { hiera_file }

    ## Below lines are for debugging purpose
    #hiera = Hiera.new(:config => hiera_file)                        # <- use Hiera ruby class
    #database_nlist = hiera.lookup('contrail::params::database_name_list', nil, nil)         # <- do hiera lookup
    #config_nlist = hiera.lookup('contrail::params::config_name_list', nil, nil)         # <- do hiera lookup
    #control_nlist = hiera.lookup('contrail::params::control_name_list', nil, nil)         # <- do hiera lookup
    #compute_nlist = hiera.lookup('contrail::params::compute_name_list', nil, nil)         # <- do hiera lookup
    #collector_nlist = hiera.lookup('contrail::params::collector_name_list', nil, nil)         # <- do hiera lookup
    #host_ip = hiera.lookup('contrail::params::host_ip', nil, nil)         # <- do hiera lookup
    #openstack_iplist = hiera.lookup('contrail::params::openstack_ip_list', nil, nil)         # <- do hiera lookup
    #compute_iplist = hiera.lookup('contrail::params::compute_ip_list', nil, nil)         # <- do hiera lookup
    #webui_iplist = hiera.lookup('contrail::params::webui_ip_list', nil, nil)         # <- do hiera lookup
    #control_iplist = hiera.lookup('contrail::params::control_ip_list', nil, nil)         # <- do hiera lookup
    #config_iplist = hiera.lookup('contrail::params::config_ip_list', nil, nil)         # <- do hiera lookup
    #collector_iplist = hiera.lookup('contrail::params::collector_ip_list', nil, nil)         # <- do hiera lookup
    #repo_name = hiera.lookup('contrail::params::contrail_repo_name', nil, nil)         # <- do hiera lookup
    #pp database_nlist, host_ip, repo_name

    #let (:hiera_data) { {
        #:'config_name_list' => config_nlist,
        #:'database_name_list' => database_nlist,
        #:'control_name_list' => control_nlist,
        #:'compute_name_list' => compute_nlist ,
        #:'collector_name_list' => collector_nlist,
    #} }
    it { should_not compile }                # this is the test to check if it compiles.
  end
end
