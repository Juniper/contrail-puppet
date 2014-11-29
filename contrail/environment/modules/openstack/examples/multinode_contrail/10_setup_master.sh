#!/bin/bash
# Set up the Puppet Master

vagrant ssh puppet -c "sudo service iptables stop; \
wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb; \
sudo dpkg -i puppetlabs-release-precise.deb; \
sudo apt-get update; \
sudo apt-get install puppetmaster-passenger; \
sudo apt-get install puppetmaster; \
sudo rmdir /etc/puppet/modules || sudo unlink /etc/puppet/modules; \
sudo ln -s /vagrant/modules /etc/puppet/modules; \
sudo ln -s /vagrant/site.pp /etc/puppet/manifests/site.pp; \
sudo service puppetmaster start;\
sudo puppet agent -t;"
