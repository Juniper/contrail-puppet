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

    cmd_to_execute= "grep -qx exec_vnc_galera \
                        /etc/contrail/contrail_openstack_exec.out"

    for host in host_ip_list:
        i = 0
        username = host_user_list[i]
        password = host_password_list[i]

        ssh = paramiko.SSHClient()
        ssh.load_system_host_keys()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(host, 22, username, password)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd_to_execute)
        if ssh_stdout.channel.recv_exit_status() != 0 :
            sys.exit(1)

if __name__ == "__main__":
    main(sys.argv[1:])
