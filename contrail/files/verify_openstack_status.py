#!/usr/bin/python
#
# Copyright (c) 2013 Juniper Networks, Inc. All rights reserved.
#
from __future__ import print_function
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

    cmd_to_execute= "supervisorctl -s http://localhost:9010 status | grep -e cinder-api -e cinder-scheduler -e glance-api -e glance-registry -e keystone -e nova-api -e nova-conductor -e nova-console -e nova-consoleauth -e nova-novncproxy -e nova-objectstore -e nova-scheduler"

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
        output_str = ssh_stdout.read()
        lines = output_str.split("\n")
        for item in lines[:-1]:
            if 'RUNNING' not in item:
                restart_cmd = "service supervisor-openstack restart"
                ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(restart_cmd)
                sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
