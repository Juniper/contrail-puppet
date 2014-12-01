#!/bin/bash

vagrant destroy compute -f
vagrant up compute
vagrant ssh puppet -c "sudo puppet cert clean compute.localdomain"
./40_deploy_nodes.sh
vagrant ssh puppet -c "sudo puppet cert sign --all"
./40_deploy_nodes.sh
