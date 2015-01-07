#!/bin/python

import paramiko
import sys, getopt, string
import os, stat
from stat import S_ISDIR
import commands

def sftp_get_recursive(path, dest, sftp):
    item_list = sftp.listdir(path)
    dest = str(dest)

    if not os.path.isdir(dest):
#        local("mkdir %s" % dest)
        os.mkdir(dest)	

    for item in item_list:
        item = str(item)

        if S_ISDIR(sftp.stat(path + "/" + item).st_mode):
            sftp_get_recursive(path + "/" + item, dest + "/" + item, sftp)
        else:
            sftp.get(path + "/" + item, dest + "/" + item)

def main(argv):
    print 'test'
    master  = ''
    key_dir = ''
    user_nane = ''
    passwd = ''

    """
    try:
        opts, args = getopt.getopt(argv,"m:k:u:p",["master=","key_dir=","user_name=","passwd="])
    except getopt.GetoptError:
        print 'test.py -i <inputfile> -o <outputfile>'
        sys.exit(2)
    import pdb; pdb.set_trace()
    for opt, arg in opts:
        if opt == '-h':
            print 'test.py -i <inputfile> -o <outputfile>'
            sys.exit()
        elif opt in ("-m", "--master"):
            master = arg
        elif opt in ("-k", "--key_dir"):
            key_dir  = arg
        elif opt in ("-u", "--user_name"):
            user_name = arg
        elif opt in ("-p", "--passwd"):
            passwd = arg

    print "master" + master
    print "key_dir" + key_dir 
    """
    master = sys.argv[1] 
    key_dir = sys.argv[2]
    user_name = sys.argv[3]
    passwd = sys.argv[4]

    status,output = commands.getstatusoutput("scp -o stricthostkeychecking=no -r %s@%s:/etc/keystone/ssl /etc/keystone/" % \
                                      (user_name, master))
    print output
    if status != 0:
        sys.exit(1)


    status,output = commands.getstatusoutput("chmod -R 777 /etc/keystone/ssl")
    print output
    if status != 0:
        sys.exit(1)


    status,output = commands.getstatusoutput("rm -rf /tmp/keystone-signing-*")
    print output
    if status != 0:
        sys.exit(1)


    status,output = commands.getstatusoutput("service keystone restart")
    print output
    if status != 0:
        sys.exit(1)



if __name__ == "__main__":
 main(sys.argv[1:])
