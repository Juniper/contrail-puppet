#!/usr/bin/python
#
# Copyright (c) 2013 Juniper Networks, Inc. All rights reserved.
#
import sys
import argparse
import ConfigParser
import commands
import itertools
import paramiko
import sys, getopt, string
import os, stat
from stat import S_ISDIR

def main(args_str=None):
    host_ip_list_str = sys.argv[1]
    host_user_list_str = sys.argv[2]
    host_password_list_str = sys.argv[3]

    host_ip_list = host_ip_list_str.split(",")
    host_user_list = host_user_list_str.split(",")
    host_password_list = host_password_list_str.split(",")

    cmd_to_execute= "/etc/contrail/contrail_setup_utils/openstack-get-config --get /etc/keystone/keystone.conf identity default_domain_id"

    DEFAULT_DOMAIN_ID = ""
    for host in host_ip_list:
        i = 0
        print host
        username = host_user_list[i]
        password = host_password_list[i]

        i=i+1
        ssh = paramiko.SSHClient()
        ssh.load_system_host_keys()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(host, 22, username, password)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd_to_execute)
        for line in ssh_stdout.read().splitlines():
          print(line)
          print host
          DEFAULT_DOMAIN_ID=line
          break

        if ssh_stdout.channel.recv_exit_status() != 0 :
          continue

    if DEFAULT_DOMAIN_ID == "":
        sys.exit(0)

    cmd_to_execute= "openstack-config --set /etc/keystone/keystone.conf identity default_domain_id " + DEFAULT_DOMAIN_ID
    print cmd_to_execute
    for host in host_ip_list:
        i = 0
        print host
        username = host_user_list[i]
        password = host_password_list[i]

        i=i+1
        ssh = paramiko.SSHClient()
        ssh.load_system_host_keys()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(host, 22, username, password)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd_to_execute)

        if ssh_stdout.channel.recv_exit_status() != 0 :
            sys.exit(1)

        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command("service keystone restart")
        if ssh_stdout.channel.recv_exit_status() != 0 :
            sys.exit(1)

if __name__ == "__main__":
    main(sys.argv[1:])
