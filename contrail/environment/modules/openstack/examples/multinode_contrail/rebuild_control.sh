#!/bin/bash

vagrant destroy control -f
vagrant destroy control2 -f
vagrant destroy control3 -f
sleep 10
vagrant up control control2 control3 puppet
sleep 10
vagrant ssh puppet -c "sudo puppet cert clean control.localdomain"
vagrant ssh puppet -c "sudo puppet cert clean control2.localdomain"
vagrant ssh puppet -c "sudo puppet cert clean control3.localdomain"
./30_deploy_control.sh
vagrant ssh puppet -c "sudo puppet cert sign --all"
./30_deploy_control.sh
