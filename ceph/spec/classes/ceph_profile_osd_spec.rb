#
#  Copyright (C) 2014 Nine Internet Solutions AG
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#  Author: David Gurtner <david@nine.ch>
#
require 'spec_helper'

describe 'ceph::profile::osd' do

  shared_examples_for 'ceph profile osd' do
    context 'with the default osd defined in common.yaml' do

      before :each do
        facts.merge!( :hostname => 'osd')
      end

      it { should contain_ceph__key('client.bootstrap-osd').with(
        :keyring_path     => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
        :secret           => 'AQARG3JTsDDEHhAAVinHPiqvJkUi5Mww/URupw==')
      }
      it { should contain_ceph__osd('/dev/sdc').with(:journal => '/dev/sdb1') }
      it { should contain_ceph__osd('/dev/sdd').with(:journal => '/dev/sdb2') }
    end

    context 'with the host specific first.yaml' do

      before :each do
        facts.merge!( :hostname => 'first')
      end

      it { should contain_ceph__key('client.bootstrap-osd').with(
        :keyring_path     => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
        :secret           => 'AQARG3JTsDDEHhAAVinHPiqvJkUi5Mww/URupw==')
      }
      it { should contain_ceph__osd('/dev/sdb').with( :journal => '/tmp/journal') }
    end
  end

  describe 'on Debian' do

    let :facts do
      {
        :osfamily         => 'Debian',
        :lsbdistcodename  => 'wheezy',
        :operatingsystem  => 'Debian',
      }
    end

    # dont actually run any tests. these cannot run under puppet 2.7
    # TODO: uncomment once 2.7 is deprecated
    #it_configures 'ceph profile osd'
  end

  describe 'on Ubuntu' do

    let :facts do
      {
        :osfamily         => 'Debian',
        :lsbdistcodename  => 'precise',
        :operatingsystem  => 'Ubuntu',
      }
    end

    # dont actually run any tests. these cannot run under puppet 2.7
    # TODO: uncomment once 2.7 is deprecated
    #it_configures 'ceph profile osd'
  end

  describe 'on RedHat' do

    let :facts do
      {
        :osfamily         => 'RedHat',
        :operatingsystem  => 'RHEL6',
      }
    end

    # dont actually run any tests. these cannot run under puppet 2.7
    # TODO: uncomment once 2.7 is deprecated
    #it_configures 'ceph profile osd'
  end
end
# Local Variables:
# compile-command: "cd ../.. ;
#    BUNDLE_PATH=/tmp/vendor bundle install ;
#    BUNDLE_PATH=/tmp/vendor bundle exec rake spec
# "
# End:
