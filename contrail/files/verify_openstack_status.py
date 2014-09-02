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


class VerifyOpenstackStatus(object):

    def __init__(self, args_str=None):
        self._args = None
        if not args_str:
            args_str = ' '.join(sys.argv[1:])
        self._parse_args(args_str)

        host_ip_list= self._args.host_ip_list.split(",")
        host_user_list= self._args.host_user_list.split(",")
        host_password_list= self._args.host_password_list.split(",")
        
        # Returning the status for all openstack process first and then verifying the status 
        all_status_up = True 
        cmd_to_execute= "supervisorctl -s http://localhost:9010 status | grep -e cinder-api -e cinder-scheduler -e glance-api -e glance-registry -e keystone -e nova-api -e nova-conductor -e nova-console -e nova-consoleauth -e nova-novncproxy -e nova-objectstore -e nova-scheduler"
        for openstack_ip, username, password in itertools.izip(host_ip_list, host_user_list, host_password_list):
            ssh = paramiko.SSHClient()
            ssh.load_system_host_keys()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh.connect(openstack_ip[1:-1], username=username[1:-1], password=password[1:-1])
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd_to_execute)
            output = ssh_stdout.readlines()
            for item in output:
                if 'RUNNING' not in item: all_status_up = False
      
        if all_status_up: 
            f = open('/etc/contrail/contrail_openstack_exec.out','a')
            f.write('verify_openstack_status\n') 
            f.close()   
    # end __init__

    def _parse_args(self, args_str):
        '''
        Eg. python verify_openstack_status --host_ip_list ['10.1.1.1','10.1.1.2']
                                           --host_user_list ['root','root']
                                           --host_password_list ['contrail123','contrail123']
        '''

        # Source any specified config/ini file
        # Turn off help, so we print all options in response to -h
        conf_parser = argparse.ArgumentParser(add_help=False)
        args, remaining_argv = conf_parser.parse_known_args(args_str.split())

        defaults = {
            'host_user_list': ['root','root'],
            'host_password_list': ['c0ntrail123','c0ntrail123'],
        }

        # Override with CLI options
        # Don't surpress add_help here so it will handle -h
        parser = argparse.ArgumentParser(
            # Inherit options from config_parser
            parents=[conf_parser],
            # print script description with -h/--help
            description=__doc__,
            # Don't mess with format of description
            formatter_class=argparse.RawDescriptionHelpFormatter,
        )
        parser.set_defaults(**defaults)

        parser.add_argument("--host_ip_list", help="List of openstack node")
        parser.add_argument("--host_user_list", help="List of user name for openstack node")
        parser.add_argument("--host_password_list", help="List of password for openstack node")
        self._args = parser.parse_args(remaining_argv)

    # end _parse_args

# end class VerifyOpenstackStatus


def main(args_str=None):
    VerifyOpenstackStatus(args_str)
# end main

if __name__ == "__main__":
    main()
