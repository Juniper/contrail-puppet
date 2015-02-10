#!/bin/bash
function get_tenant() {
    id=$(keystone tenant-list | grep ' '$1' ' | awk '{print $2;}')
    if [ -z "$id" ]; then
	id=$(keystone tenant-create --name=$1 | grep ' id ' | awk '{print $4}')
    fi
    echo $id
}

function get_user() {
    id=$(keystone user-list | grep $1 | awk '{print $2;}')
    EMAIL="@example.com"
    if [ -z $id ]; then
	id=$(keystone user-create --name=$1 --pass="$ADMIN_PASSWORD" \
	         --email=$1$EMAIL | grep ' id ' | awk '{print $4;}')
    fi
    echo $id
}

source /etc/contrail/keystonerc
ADMIN_TENANT=$(get_tenant admin)
DEMO_TENANT=$(get_tenant demo)
ADMIN_USER=$(get_user admin)
DEMO_USER=$(get_user demo)

mkdir -p /etc/contrail
EC2RC=${EC2RC:-/etc/contrail/ec2rc}

# create ec2 creds and parse the secret and access key returned
RESULT=$(keystone ec2-credentials-create --tenant-id=$ADMIN_TENANT --user-id=$ADMIN_USER)
ADMIN_ACCESS=`echo "$RESULT" | grep access | awk '{print $4}'`
ADMIN_SECRET=`echo "$RESULT" | grep secret | awk '{print $4}'`

RESULT=$(keystone ec2-credentials-create --tenant-id=$DEMO_TENANT --user-id=$DEMO_USER)
DEMO_ACCESS=`echo "$RESULT" | grep access | awk '{print $4}'`
DEMO_SECRET=`echo "$RESULT" | grep secret | awk '{print $4}'`

# write the secret and access to ec2rc
cat > $EC2RC <<EOF
ADMIN_ACCESS=$ADMIN_ACCESS
ADMIN_SECRET=$ADMIN_SECRET
DEMO_ACCESS=$DEMO_ACCESS
DEMO_SECRET=$DEMO_SECRET
EOF

unset OS_USERNAME
unset SERVICE_TOKEN
unset OS_SERVICE_ENDPOINT
