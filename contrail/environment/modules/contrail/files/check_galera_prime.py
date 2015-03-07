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
    os_master_ip = sys.argv[1]
    os_master_user = sys.argv[2]
    os_master_pass = sys.argv[3]


    cmd_to_execute= "grep -qx exec_vnc_galera \
                        /etc/contrail/contrail_ha_exec.out"

    username = os_master_user
    password = os_master_pass
    host = os_master_ip

    ssh = paramiko.SSHClient()
    ssh.load_system_host_keys()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print "Connection to %s" % (host)
    ssh.connect(host, 22, username, password)
    ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd_to_execute)
    if ssh_stdout.channel.recv_exit_status() != 0 :
	print "Gallera didnt execute at %s" % (host)
	sys.exit(1)

if __name__ == "__main__":
    main(sys.argv[1:])
