#!/usr/bin/python
#
# Copyright (c) 2013 Juniper Networks, Inc. All rights reserved.
#
import commands
import sys
import paramiko
import os.path

def create_ssh_keys():
    if not os.path.isfile('/root/.ssh/id_rsa') and not os.path.isfile('/root/.ssh/id_rsa.pub'):
        commands.getstatusoutput('ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""')
    elif not os.path.isfile('/root/.ssh/id_rsa') or not os.path.isfile('/root/.ssh/id_rsa.pub'):
        commands.getstatusoutput('rm -rf /root/.ssh/id_rsa*')
        commands.getstatusoutput('ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""')



def main(args_str=None):
    compute_host_list_str = sys.argv[1]
    config_host_list_str = sys.argv[2]
    compute_host_list = compute_host_list_str.split(",")
    config_host_list = config_host_list_str.split(",")

    amqp_host_list = config_host_list
    cmon_param = '/etc/contrail/ha/cmon_param'
    #TODO amqp_role ?
#    amqp_role = sys.argv[3]

    computes = 'COMPUTES=("' + '" "'.join(compute_host_list) + '")'
    commands.getstatusoutput("echo '%s' >> %s" % (computes, cmon_param))
    commands.getstatusoutput("echo 'COMPUTES_SIZE=${#COMPUTES[@]}' >> %s" % cmon_param)
    commands.getstatusoutput("echo 'COMPUTES_USER=root' >> %s" % cmon_param)
    commands.getstatusoutput("echo 'PERIODIC_RMQ_CHK_INTER=60' >> %s" % cmon_param)
    amqps = 'DIPHOSTS=("' + '" "'.join(amqp_host_list) + '")'
    commands.getstatusoutput("echo '%s' >> %s" % (amqps, cmon_param))
    commands.getstatusoutput("echo 'DIPS_HOST_SIZE=${#DIPHOSTS[@]}' >> %s" % cmon_param)


    #Copy the ssh keys of openstack to every compute
    create_ssh_keys()
    status,output = commands.getstatusoutput("cat /root/.ssh/id_rsa.pub")
    publick_key = output
    port = 22
    username = "root"
    password = "c0ntrail123"
    for compute_host in compute_host_list:
        s = paramiko.SSHClient()
        s.load_system_host_keys()
        s.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        s.connect(compute_host, port, username, password)
        command = "mkdir -p /root/ssh/"
        s.exec_command(command)
        command = "echo %s > /root/.ssh/authorized_keys" % output
        s.exec_command(command)
        s.close()

if __name__ == "__main__":
    main(sys.argv[1:])       
