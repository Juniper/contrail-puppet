#!/bin/bash

# Remainder of nodes follow
vagrant ssh compute -c "sudo apt-get install -y rubygems;\
sudo apt-get -y remove nfs-common;\
sudo puppet agent -t"

wait
