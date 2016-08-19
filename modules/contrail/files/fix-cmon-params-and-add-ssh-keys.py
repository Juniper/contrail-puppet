#!/usr/bin/python
#
# Copyright (c) 2013 Juniper Networks, Inc. All rights reserved.
#
import commands
import sys
import paramiko
import os.path

def main(args_str=None):
    compute_host_list_str = sys.argv[1]
    config_host_list_str = sys.argv[2]
    compute_host_list = compute_host_list_str.split(",")
    compute_sz = len(compute_host_list)
    config_host_list = config_host_list_str.split(",")

    amqp_host_list = config_host_list
    amqp_sz = len(amqp_host_list)
    cmon_param = '/etc/contrail/ha/cmon_param'
    #TODO amqp_role ?
#    amqp_role = sys.argv[3]

    computes = 'COMPUTES=("' + '" "'.join(compute_host_list) + '")'
    commands.getstatusoutput("echo '%s' >> %s" % (computes, cmon_param))
    commands.getstatusoutput("echo 'COMPUTES_SIZE=%s' >> %s" % ("${#COMPUTES[@]}", cmon_param))
    commands.getstatusoutput("echo 'COMPUTES_USER=root' >> %s" % cmon_param)
    amqps = 'DIPHOSTS=("' + '" "'.join(amqp_host_list) + '")'
    commands.getstatusoutput("echo '%s' >> %s" % (amqps, cmon_param))
    commands.getstatusoutput("echo 'DIPS_HOST_SIZE=%s' >> %s" % ("${#DIPHOSTS[@]}", cmon_param))


if __name__ == "__main__":
    main(sys.argv[1:])       
