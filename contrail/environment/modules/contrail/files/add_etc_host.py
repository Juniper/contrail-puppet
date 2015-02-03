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
    config_ip_list_str = sys.argv[1]
    config_name_list_str = sys.argv[2]

    config_ip_list = config_ip_list_str.split(",")
    config_name_list = config_name_list_str.split(",")

    for config_name, config_ip in zip(config_name_list, config_ip_list):
        status, output = commands.getstatusoutput("echo '%s    %sctl' >> /etc/hosts" %(config_ip, config_name))

if __name__ == "__main__":
    main(sys.argv[1:])

