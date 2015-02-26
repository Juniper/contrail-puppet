#!/usr/bin/python
#
# Copyright (c) 2013 Juniper Networks, Inc. All rights reserved.
#
import commands
import sys


def main(args_str=None):
    memory = "2048"
    listen_ip = sys.argv[1]
    memcache_conf='/etc/memcached.conf'
    cmd = 'grep "\-m " %s' % memcache_conf
    status,output = commands.getstatusoutput(cmd)
    if status:
        #Write option to memcached config file
        cmd = 'echo "-m %s" >> %s' % (memory, memcache_conf)
        status,output = commands.getstatusoutput(cmd)
    else:
        cmd = "sed -i -e 's/\-m.*/\-m %s/' %s" % (memory, memcache_conf)
        status,output = commands.getstatusoutput(cmd)
    cmd = 'grep "\-l " %s' % memcache_conf 
    status,output = commands.getstatusoutput(cmd)
    if status:
        #Write option to memcached config file
        cmd = 'echo "-l %s" >> %s' % (listen_ip, memcache_conf)
        status,output = commands.getstatusoutput(cmd)
    else:
        cmd = "sed -i -e 's/\-l.*/\-l %s/' %s" % (listen_ip, memcache_conf)
        status,output = commands.getstatusoutput(cmd)

    #tune tcp params

    if commands.getstatusoutput("grep '^net.netfilter.nf_conntrack_max' /etc/sysctl.conf")[0] != 0:
        commands.getstatusoutput('echo "net.netfilter.nf_conntrack_max = 256000" >> /etc/sysctl.conf')
    if commands.getstatusoutput("grep '^net.netfilter.nf_conntrack_tcp_timeout_time_wait' /etc/sysctl.conf")[0] != 0:
        commands.getstatusoutput('echo "net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30" >> /etc/sysctl.conf')
    if commands.getstatusoutput("grep '^net.ipv4.tcp_syncookies' /etc/sysctl.conf")[0] != 0:
        commands.getstatusoutput('echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf')
    if commands.getstatusoutput("grep '^net.ipv4.tcp_tw_recycle' /etc/sysctl.conf")[0] != 0:
        commands.getstatusoutput('echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf')
    if commands.getstatusoutput("grep '^net.ipv4.tcp_tw_reuse' /etc/sysctl.conf")[0] != 0:
        commands.getstatusoutput('echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf')
    if commands.getstatusoutput("grep '^net.ipv4.tcp_fin_timeout' /etc/sysctl.conf")[0] != 0:
        commands.getstatusoutput('echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf')
    if commands.getstatusoutput("grep '^net.unix.max_dgram_qlen' /etc/sysctl.conf")[0] != 0:
        commands.getstatusoutput('echo "net.unix.max_dgram_qlen  = 1000" >> /etc/sysctl.conf')

    commands.getstatusoutput('sysctl -p')

if __name__ == "__main__":
     main(sys.argv[1:])
