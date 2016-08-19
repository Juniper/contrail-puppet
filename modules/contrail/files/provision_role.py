import commands
import sys
import os.path

def main(args_str=None):
    role_ip_list_str = sys.argv[1]
    role_ip_list = role_ip_list_str.split(",")

    role_name_list_str = sys.argv[2]
    role_name_list = role_name_list_str.split(",")

    config_ip = sys.argv[3]
    keystone_admin_user = sys.argv[4]
    keystone_admin_password = sys.argv[5]
    keystone_admin_tenant = sys.argv[6]

    role = sys.argv[7]
    file_dir = "/opt/contrail/utils/"

    if ( role == "config" ):
        file_name = file_dir + "provision_config_node.py"
    elif ( role == "database" ):
        file_name = file_dir + "provision_database_node.py"
    elif ( role == "collector"):
        file_name = file_dir + "provision_analytics_node.py"
    else:
        sys.exit(-1)

    for role_ip, role_name in zip(role_ip_list, role_name_list):
        provision_cmd = "python %s --api_server_ip %s --host_name %s --host_ip %s" \
                            " --oper add --admin_user %s --admin_password %s" \
                             " --admin_tenant_name %s" % \
                                (file_name, config_ip, role_name, role_ip,
                                  keystone_admin_user, keystone_admin_password,
                                  keystone_admin_tenant)
        print ("Executing command %s" % (provision_cmd))
        status,output = commands.getstatusoutput(provision_cmd)
        if status != 0:
            sys.exit(-1)

    sys.exit(0)

if __name__ == "__main__":
         main(sys.argv[1:])

