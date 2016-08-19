import commands
import sys
import os.path

def main(args_str=None):
    openstack_ip_list_str = sys.argv[1]
    os_ip_list = openstack_ip_list_str.split(",")
    number_openstack_nodes = len(os_ip_list)

    status,output = commands.getstatusoutput("cat /etc/contrail/mysql.token")
    mysql_token = output
    status,output = commands.getstatusoutput('mysql -uroot -p%s -e "show status like \'wsrep_local_state_comment\'"' %  mysql_token )
    print "wsrep_local_state_comment: %s" % output
    if output.find("Synced") == -1:
        sys.exit(1)
    status,output = commands.getstatusoutput('mysql -uroot -p%s -e "show status like \'wsrep_local_state\'"' %  mysql_token)
    print "wsrep_local_state: %s" % output
    if output.find("4") == -1:
    #if output.find(str(number_openstack_nodes)) == -1:
        sys.exit(1)
    status,output = commands.getstatusoutput('mysql -uroot -p%s -e "show status like \'wsrep_cluster_size\'"' %  mysql_token )
    print "wsrep_cluster_size: %s" % output
    #if output.find("4") == -1:
    if output.find(str(number_openstack_nodes)) == -1:
        sys.exit(1)
#        uuid, output = commands.getstatusoutput("cat /var/lib/mysql/grastate.dat | grep uuid | awk '{print $2;}'")
#        commands.getstatusoutput("service mysql restart")
      
#        for os_ip in os_ip_list:
#          if not os.path.exists("/etc/clear_mysql"):
#              status,output = commands.getstatusoutput('ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %s "rm -rf /var/lib/mysql/grastate.dat"' % (os_ip))
#              status,output = commands.getstatusoutput('ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %s "service mysql restart"' % (os_ip))
#              print "cleaning mysql in %s" % (output)
#              open("/etc/clear_mysql", 'a').close() 
 
if __name__ == "__main__":
         main(sys.argv[1:])

