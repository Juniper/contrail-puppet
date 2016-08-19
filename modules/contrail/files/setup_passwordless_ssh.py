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
    host_list_str = sys.argv[1]
    user_list_str = sys.argv[2]
    password_list_str = sys.argv[3]
    host_list = host_list_str.split(",") 
    user_list = user_list_str.split(",")
    password_list = password_list_str.split(",")

    port = 22
    i = 0
    create_ssh_keys()
    status,output = commands.getstatusoutput("cat /root/.ssh/id_rsa.pub")
    publick_key = output
    for host in host_list:
        s = paramiko.SSHClient()
        s.load_system_host_keys()
        s.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        username = user_list[i]
        password = password_list[i]
#        print ("Connectin to %s with %s:%s" % host, username,password)
        s.connect(host, port, username, password)
        command = "mkdir -p /root/.ssh/"
        s.exec_command(command)
        command = "echo %s >> /root/.ssh/authorized_keys" % output
        s.exec_command(command)
        s.close()
        i = i + 1

    for host in host_list:
        cmd = "ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %s true" % (host)
        res, output = commands.getstatusoutput(cmd) 
        if res !=0 :
            sys.exit(-1)


if __name__ == "__main__":
     main(sys.argv[1:])

