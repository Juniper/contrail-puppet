#!/bin/bash

# Kick off the puppet runs, control is first for databases
vagrant ssh control -c "sudo apt-get -y install rubygems; \
sudo puppet agent -t;" &
vagrant ssh control2 -c "sudo apt-get -y install rubygems; \
sudo puppet agent -t;" &
vagrant ssh control3 -c "sudo apt-get -y install rubygems; \
sudo puppet agent -t;" &
wait
