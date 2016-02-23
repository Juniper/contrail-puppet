class contrail::database::config_cassandra (
  $contrail_logoutput = $::contrail::params::contrail_logoutput,
  $host_control_ip = $::contrail::params::host_ip,
  $database_dir = $::contrail::params::database_dir,
  $cassandra_seeds,
  $contrail_cassandra_dir,
) {

      # Moved Cassandra config to augeas from templates
      $cassandra_config_file ="${contrail_cassandra_dir}/cassandra.yaml"
      $cassandra_env_file="${contrail_cassandra_dir}/cassandra-env.sh"
      $cassandra_seeds_join = join($cassandra_seeds, ',')
      #$cassandra_yaml_config = { 'cassandra_config' => {
      #        'listen_address' => $host_control_ip,
      #        'cluster_name' => "\'Contrail\'",
      #        'rpc_address' => $host_control_ip,
      #        'num_tokens' => "256",
      #        'saved_caches_directory' => "${database_dir}/saved_caches",
      #        'commitlog_directory' => "${database_dir}/commitlog",
      #    },
      #}
      package {'cassandra':
                ensure => latest,
                configfiles => "replace",
      } ->
      file_line { 'Config Cassandra listen_address':
          path => $cassandra_config_file,
          line => "listen_address: ${host_control_ip}",
          match   => "^listen_address:.*$",
      } ->
      file_line { 'Config Cassandra rpc_address':
          path => $cassandra_config_file,
          line => "rpc_address: ${host_control_ip}",
          match   => "^rpc_address:.*$",
      } ->
      file_line { 'Config Cassandra num_tokens':
          path => $cassandra_config_file,
          line => 'num_tokens: 256',
          match   => "# num_tokens:.*$",
      } ->
      file_line { 'Config Cassandra cluster_name':
          path => $cassandra_config_file,
          line => 'cluster_name: \'Contrail\'',
          match   => "^cluster_name:.*$",
      } ->
      file_line { 'Config Cassandra saved_caches_dir':
          path => $cassandra_config_file,
          line => "saved_caches_directory: ${database_dir}/saved_caches",
          match   => "^saved_caches_directory:.*$",
      } ->
      file_line { 'Config Cassandra commitlog_dir':
          path => $cassandra_config_file,
          line => "commitlog_directory: ${database_dir}/commitlog",
          match   => "^commitlog_directory:.*$",
      } ->
      file_line { 'Removing Cassandra initial_token':
          path => $cassandra_config_file,
          line => '# initial_token',
          match   => "^initial_token:.*$",
      } ->
      file_line { 'Config Cassandra Seeds':
        path => $cassandra_config_file,
        line => "          - seeds: \"${cassandra_seeds_join}\"",
        match   => "          - seeds:.*$",
      } ->
      file_line { 'Config File Directories':
        path => $cassandra_config_file,
        line => "    - ${database_dir}/data",
        match   => "    - /var/lib/cassandra/data",
      } ->
      file_line { 'ENV Cassandra file setting':
        path => $cassandra_env_file,
        line => 'JVM_OPTS="$JVM_OPTS -Xss512k"',
        match   => "JVM_OPTS=\"\$JVM_OPTS -Xss.*\"",
      }
}
