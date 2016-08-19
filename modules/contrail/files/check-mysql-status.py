import commands
import sys
import os.path

def main(args_str=None):

    status,output = commands.getstatusoutput("cat /etc/contrail/mysql.token")
    mysql_token = output
    status,output = commands.getstatusoutput('service mysql status')
    
#    if status != 0:
#        sys.exit(0)

#   If we are not able to connect to mysql,its probably stucik , kill it!
    status,output = commands.getstatusoutput('mysql -uroot -p%s -e "show status like \'wsrep_cluster_size\'"' %  mysql_token )
    print "wsrep_cluster_size: %s" % output
    #if output.find("4") == -1:
    if status != 0:
        status,output = commands.getstatusoutput('pkill -9 mysql')

if __name__ == "__main__":
         main(sys.argv[1:])

