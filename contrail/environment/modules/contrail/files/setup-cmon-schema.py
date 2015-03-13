#!/usr/bin/python
#
# Copyright (c) 2013 Juniper Networks, Inc. All rights reserved.
#
import argparse
import ConfigParser
import os
import sys
import commands

def main(argv):
    os_master = sys.argv[1]
    self_ip = sys.argv[2]
    internal_vip = sys.argv[3]
    openstack_ip_list_str = sys.argv[4]
    openstack_ip_list = openstack_ip_list_str.split(",")

    mysql_svc = 'mysql'

    status,output = commands.getstatusoutput("cat /etc/contrail/mysql.token") 

    mysql_token = output

    # Create cmon schema
    status,output = commands.getstatusoutput('mysql -u root -p%s -e "CREATE SCHEMA IF NOT EXISTS cmon"' % mysql_token)
    status,output = commands.getstatusoutput('mysql -u root -p%s < /usr/local/cmon/share/cmon/cmon_db.sql' % mysql_token)
    status,output = commands.getstatusoutput('mysql -u root -p%s < /usr/local/cmon/share/cmon/cmon_data.sql' % mysql_token)

    # insert static data
    status,output = commands.getstatusoutput('mysql -u root -p%s -e "use cmon; insert into cluster(type) VALUES (\'galera\')"' % mysql_token)
    mysql_cmd =  "mysql -uroot -p%s -e" % mysql_token
    if os_master == self_ip:
        mysql_cmon_user_cmd = 'mysql -u root -p%s -e "CREATE USER \'cmon\'@\'%s\' IDENTIFIED BY \'cmon\'"' % (
                                           mysql_token, 'localhost')
        status,output = commands.getstatusoutput(mysql_cmon_user_cmd)
        mysql_cmon_user_cmd = 'mysql -u root -p%s -e "CREATE USER \'cmon\'@\'%s\' IDENTIFIED BY \'cmon\'"' % (
                                           mysql_token, '127.0.0.1')
        status,output = commands.getstatusoutput(mysql_cmon_user_cmd)
        mysql_cmon_user_cmd = 'mysql -u root -p%s -e "CREATE USER \'cmon\'@\'%s\' IDENTIFIED BY \'cmon\'"' % (
                                           mysql_token, internal_vip)
        status,output = commands.getstatusoutput(mysql_cmon_user_cmd)


        status,output = commands.getstatusoutput('%s "GRANT ALL PRIVILEGES on *.* TO cmon@%s IDENTIFIED BY \'cmon\' WITH GRANT OPTION"' %
                   (mysql_cmd, 'localhost'))
        status,output = commands.getstatusoutput('%s "GRANT ALL PRIVILEGES on *.* TO cmon@%s IDENTIFIED BY \'cmon\' WITH GRANT OPTION"' %
                   (mysql_cmd, '127.0.0.1'))
        status,output = commands.getstatusoutput('%s "GRANT ALL PRIVILEGES on *.* TO cmon@%s IDENTIFIED BY \'cmon\' WITH GRANT OPTION"' %
                   (mysql_cmd, internal_vip))

    for openstack_ip in openstack_ip_list:
        status,output = commands.getstatusoutput('%s "GRANT ALL PRIVILEGES on *.* TO cmon@%s IDENTIFIED BY \'cmon\' WITH GRANT OPTION"' %
                   (mysql_cmd, openstack_ip))

    mysql_cmon_user_cmd = 'mysql -u root -p%s -e "CREATE USER \'cmon\'@\'%s\' IDENTIFIED BY \'cmon\'"' % (
                                           mysql_token, self_ip)
    status,output = commands.getstatusoutput(mysql_cmon_user_cmd)
    status,output = commands.getstatusoutput('%s "GRANT ALL PRIVILEGES on *.* TO cmon@%s IDENTIFIED BY \'cmon\' WITH GRANT OPTION"' %
                   (mysql_cmd, self_ip))
#    status,output = commands.getstatusoutput("service mysql restart")

if __name__ == "__main__":
     main(sys.argv[1:])
