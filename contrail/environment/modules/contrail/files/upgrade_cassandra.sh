#!/bin/bash
set -x
this_host=$1; shift
database_dir=$1; shift
contrail_package_name=$1
cassandra_version=''
cassandra_version=`dpkg -s cassandra | grep Version | awk '{print $2}'`
version_check=`echo -e "$cassandra_version\n2.1.9" | sort -V | head -n1`
if [ "$version_check" == "2.1.9" ] || [ "$cassandra_version" == '' ]; then
  # Don't do upgrade
  exit
fi
if [ "$cassandra_version" == "1.2.11" ]; then
  # Install intermediate, configure intermediate, and start it
  nodetool upgradesstables
  if [ $? != "0" ]; then
    exit 1
  fi
  service supervisor-database stop
  wget -q http://puppet/contrail/repo/${contrail_package_name}/cassandra_2.0.17_all.deb
  dpkg --force-depends --force-overwrite --force-confnew --install cassandra_2.0.17_all.deb
  service cassandra stop
  chown -R cassandra:cassandra ${database_dir}
  chown -R cassandra:cassandra /var/log/cassandra
  sed -i -e "s|listen_address.*|listen_address: $this_host|" /etc/cassandra/cassandra.yaml
  sed -i -e "s|cluster_name.*|cluster_name: \'Contrail\'|" /etc/cassandra/cassandra.yaml
  sed -i -e "s|rpc_address.*|rpc_address: $this_host|" /etc/cassandra/cassandra.yaml
  sed -i -e "s|# num_tokens.*|num_tokens: 256|" /etc/cassandra/cassandra.yaml
  sed -i -e "s|^initial_token.*|# initial_token:|" /etc/cassandra/cassandra.yaml
  sed -i -e "s|saved_caches_directory.*|saved_caches_directory: $database_dir/saved_caches|" /etc/cassandra/cassandra.yaml
  sed -i -e "s|commitlog_directory.*|commitlog_directory: $database_dir/commitlog|" /etc/cassandra/cassandra.yaml
  sed -i -e "s|    - /var/lib/cassandra/data|    - $database_dir/data|" /etc/cassandra/cassandra.yaml
  sed -i 's/JVM_OPTS=\"\$JVM_OPTS -Xss.*\"/JVM_OPTS=\"\$JVM_OPTS -Xss512k\"/g' /etc/cassandra/cassandra-env.sh
  service cassandra start; sleep 10
fi
# At this point, the 2.0.17 cassandra has been installed and has been started
# If script is running for the second time, that means we were not able to connect to cassandra previously
cassandra_cli_status="1"
cassandra_cli_cmd=" "
re_try_count=0
success=0
for i in `seq 1 10`;
do
cassandra_cli_cmd=$(cassandra-cli --host $this_host --batch < /dev/null | grep 'Connected to:')
cassandra_cli_status=$?
sleep 5
done
if [ $success == "1" ]; then
  # We have successfully connected to cassandra with version 2.0.17
  echo "Successful cassandra connect to 2.0.17: $cassandra_cli_cmd"
  nodetool upgradesstables
  if [ $? != "0" ]; then
    exit 1
  fi
  service cassandra stop
else
  echo "Connection failure"
  exit 1
fi
