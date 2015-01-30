# Copyright (c) 2013 Juniper Networks, Inc. All rights reserved.
#
import commands
import sys



def main(args_str=None):

    ports_str = sys.argv[1]

    status, output = commands.getstatusoutput("cat /proc/sys/net/ipv4/ip_local_reserved_ports")
    if status != 0:
        sys.exit(-1)
    else:
        existing_ports = output

    status, output = commands.getstatusoutput("sysctl -w net.ipv4.ip_local_reserved_ports=%s,%s" % (ports_str, existing_ports))

    if status != 0:
        sys.exit(-1)

    status, output = commands.getstatusoutput("grep '^net.ipv4.ip_local_reserved_ports' /etc/sysctl.conf > /dev/null 2>&1")


    if status != 0:  
        status, output = commands.getstatusoutput('echo "net.ipv4.ip_local_reserved_ports = %s" >> /etc/sysctl.conf' % ports_str)
    else:
        status, output = commands.getstatusoutput("sed -i 's/net.ipv4.ip_local_reserved_ports\s*=\s*/net.ipv4.ip_local_reserved_ports=%s,/' /etc/sysctl.conf" % ports_str)

    if status != 0:
        sys.exit(-1)

if __name__ == "__main__":
     main(sys.argv[1:])
