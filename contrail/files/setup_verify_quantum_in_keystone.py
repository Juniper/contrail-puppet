import argparse
import pdb
import commands
import sys
import requests
import json
import time

def setup_quantum(contrail_openstack_ip, contrail_config_ip, contrail_ks_admin_tenant, contrail_ks_admin_user, contrail_ks_admin_passwd, contrail_service_token, contrail_region_name):

    cmd = "python /opt/contrail/bin/setup-quantum-in-keystone --ks_server_ip %s --quant_server_ip %s  --tenant %s  --user %s  --password %s --svc_password %s  --region_name %s" %(contrail_openstack_ip, contrail_config_ip, contrail_ks_admin_tenant, contrail_ks_admin_user, contrail_ks_admin_passwd, contrail_service_token, contrail_region_name)  
    ret,output = commands.getstatusoutput(cmd) 
    if (ret):
	sys.exit(-1)

def verify_neutron_port(contrail_openstack_ip, contrail_ks_admin_tenant, contrail_ks_admin_user, contrail_ks_admin_passwd):
    neutron_port_configured = 0
    neutron_port=str(9696)
    openstack_ip = sys.argv[1]

    # POST REQ
    payload = str({"auth": {"tenantName": "%s", "passwordCredentials": {"username": "%s", "password": "%s"}}}) %(contrail_ks_admin_tenant, contrail_ks_admin_user, contrail_ks_admin_passwd)
    url = "http://%s:5000/v2.0/tokens" %(contrail_openstack_ip)
    OST_HEADERS = {'Content-Type': 'application/json; charset="UTF-8"', 'Expect':'202-accepted'}
    payload = payload.replace("\'","\"")
    resp = requests.post(url, data=payload, headers=OST_HEADERS)

    # Manupulating the retun out put to convert into dictionary
    resp_str = str(resp.text)
    resp_dict = json.loads(resp_str)

    # Computing the token id
    token_id = resp_dict['access']['token']['id']

    # GET
    url1 = "http://%s:35357/v2.0/endpoints" %(contrail_openstack_ip)
    OST_HEADERS1 = {'X-Auth-Token': token_id, 'Expect':'202-accepted'}
    resp1 = requests.get(url1, headers=OST_HEADERS1)
    resp_str1 = str(resp1.text)
    resp_dict1 = json.loads(resp_str1)

    # Validation for port 9696 (neutron)
    for item in resp_dict1['endpoints']:
        if (neutron_port in str(item['adminurl']) and neutron_port in str(item['publicurl'])):
            neutron_port_configured = 1
    return neutron_port_configured
       

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--contrail_openstack_ip", help = "IP Address of quantum server")
    parser.add_argument("--contrail_config_ip", help = "IP Address of quantum server")
    parser.add_argument("--contrail_ks_admin_tenant", help = "Tenant ID on keystone server")
    parser.add_argument("--contrail_ks_admin_user", help = "User ID to access keystone server")
    parser.add_argument("--contrail_ks_admin_passwd", help = "Password to access keystone server")
    parser.add_argument("--contrail_service_token", help = "Quantum service password on keystone server")
    parser.add_argument("--contrail_region_name", help = "Region Name for quantum endpoint")
    args = parser.parse_args()
    while (verify_neutron_port (args.contrail_openstack_ip, args.contrail_ks_admin_tenant, args.contrail_ks_admin_user, args.contrail_ks_admin_passwd) == 0):
        time.sleep (5)
        setup_quantum (args.contrail_openstack_ip, args.contrail_config_ip, args.contrail_ks_admin_tenant, args.contrail_ks_admin_user, args.contrail_ks_admin_passwd, args.contrail_service_token, args.contrail_region_name)

if __name__ == "__main__":
    import cgitb
    cgitb.enable(format='text')
    main()
# end if __name__

