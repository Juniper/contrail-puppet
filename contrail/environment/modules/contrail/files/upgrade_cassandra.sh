#!/bin/bash
set -x
this_host=$1; shift
database_dir=$1
cassandra_version=`dpkg -s cassandra | grep Version | awk '{print $2}'`
if [ "$cassandra_version" != "1.2.11" ]; then
  # Don't do upgrade
  exit
fi
nodetool upgradesstables
service supervisor-database stop
wget http://puppet/contrail/repo/dgautam_uj_mainline_2713/cassandra_2.0.17_all.deb
dpkg --force-depends --force-overwrite --force-confnew --install cassandra_2.0.17_all.deb
service cassandra stop
chown -R cassandra:cassandra ${database_dir}
chown -R cassandra:cassandra /var/log/cassandra
sed -i -e "s|listen_address.*|listen_address: $this_host|" /etc/cassandra/cassandra.yaml
sed -i -e "s|cluster_name.*|cluster_name: \'Contrail\'|" /etc/cassandra/cassandra.yaml
sed -i -e "s|rpc_address.*|rpc_address: $this_host|" /etc/cassandra/cassandra.yaml
sed -i -e "s|# num_tokens.*|num_tokens: 256|" /etc/cassandra/cassandra.yaml
sed -i -e "s|initial_token.*|# initial_token:|" /etc/cassandra/cassandra.yaml
sed -i -e "s|saved_caches_directory.*|saved_caches_directory: $database_dir/saved_caches|" /etc/cassandra/cassandra.yaml
sed -i -e "s|commitlog_directory.*|commitlog_directory: $database_dir/commitlog|" /etc/cassandra/cassandra.yaml
sed -i -e "s|    - /var/lib/cassandra/data|    - $database_dir/data|" /etc/cassandra/cassandra.yaml
sed -i 's/JVM_OPTS=\"\$JVM_OPTS -Xss.*\"/JVM_OPTS=\"\$JVM_OPTS -Xss512k\"/g' /etc/cassandra/cassandra-env.sh
service cassandra start; sleep 10
cassandra_cli_status="0"
while [ $cassandra_cli_status != "0" ] && [ $cassandra_cli_cmd != "" ]
do
cassandra_cli_cmd=$(cassandra-cli --host $this_host --batch < /dev/null | grep 'Connected to:')
cassandra_cli_status=$?
sleep 5
done
echo "Successful cassandra connect to 2.0.17: $cassandra_cli_cmd"
nodetool upgradesstables
service cassandra stop