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
    host_ip = sys.argv[1]
    host_user = sys.argv[2]
    host_password = sys.argv[3]

    cmd_to_execute= "cat /etc/contrail/mysql.token"

    ssh = paramiko.SSHClient()
    ssh.load_system_host_keys()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host_ip, 22, host_user, host_password)
    ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd_to_execute)
    if ssh_stdout.channel.recv_exit_status() != 0 :
            sys.exit(1)
    mysql_token = ssh_stdout.read()
    mysql_token = mysql_token.strip()
    cmd_to_execute= 'mysql -uroot -p%s -e "show status like \'wsrep_local_state\'"' %  mysql_token
    ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd_to_execute)
    if ssh_stdout.channel.recv_exit_status() != 0 :
            sys.exit(1)
    output_str = ssh_stdout.read()
    if output_str.find("4") == -1:
        sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
 
