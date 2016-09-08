class contrail::config_cassandra (
  $contrail_logoutput = $::contrail::params::contrail_logoutput,
  $host_control_ip = $::contrail::params::host_ip,
  $database_dir = $::contrail::params::database_dir,
  $cassandra_cluster_name = "\'Contrail\'",
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

      $jvm_version_chk = 'sed -i -e \'s/if \[ \"\$JVM_VERSION\" \\< \"1.8\" \] && \[ \"\$JVM_PATCH_VERSION\" \\< \"25\" \] ; then/if \[ \"\$JVM_VERSION\" \\< \"1.8\" \] \&\& \[ \"\$JVM_PATCH_VERSION\" -lt \"25\" \] ; then/\' '

      file_line { 'Config Cassandra start_rpc':
          path => $cassandra_config_file,
          line => "start_rpc: true",
          match   => '^start_rpc:.*$',
      } ->
      file_line { 'Config Cassandra listen_address':
          path => $cassandra_config_file,
          line => "listen_address: ${host_control_ip}",
          match   => '^listen_address:.*$',
      } ->
      file_line { 'Config Cassandra rpc_address':
          path => $cassandra_config_file,
          line => "rpc_address: ${host_control_ip}",
          match   => '^rpc_address:.*$',
      } ->
      file_line { 'Config Cassandra num_tokens':
          path => $cassandra_config_file,
          line => 'num_tokens: 256',
          match   => '# num_tokens:.*$',
      } ->
      file_line { 'Config Cassandra cluster_name':
          path => $cassandra_config_file,
          line => "cluster_name: ${cassandra_cluster_name}",
          match   => '^cluster_name:.*$',
      } ->
      file_line { 'Config Cassandra compaction_throughput_mb_per_sec':
          path => $cassandra_config_file,
          line => "compaction_throughput_mb_per_sec: 96",
          match   => '^compaction_throughput_mb_per_sec:.*$',
      } ->
      file_line { 'Config Cassandra saved_caches_dir':
          path => $cassandra_config_file,
          line => "saved_caches_directory: ${database_dir}/saved_caches",
          match   => '^saved_caches_directory:.*$',
      } ->
      file_line { 'Config Cassandra commitlog_dir':
          path => $cassandra_config_file,
          line => "commitlog_directory: ${database_dir}/commitlog",
          match   => '^commitlog_directory:.*$',
      } ->
      file_line { 'Removing Cassandra initial_token':
          path => $cassandra_config_file,
          line => '# initial_token',
          match   => '^initial_token:.*$',
      } ->
      file_line { 'Config Cassandra Seeds':
        path => $cassandra_config_file,
        line => "          - seeds: \"${cassandra_seeds_join}\"",
        match   => '          - seeds:.*$',
      } ->
      file_line { 'Config File Directories':
        path => $cassandra_config_file,
        line => "    - ${database_dir}/data",
        match   => '    - .*/data',
      } ->
      file_line { 'Config File Remove 1':
        path => $cassandra_config_file,
        line => "#multithreaded_compaction",
        match   => '^multithreaded_compaction.*',
      } ->
      file_line { 'Config File Remove 2':
        path => $cassandra_config_file,
        line => "#row_cache_provider",
        match   => '^row_cache_provider.*',
      } ->
      file_line { 'Config File Remove 3':
        path => $cassandra_config_file,
        line => "#flush_largest_memtables_at",
        match   => '^flush_largest_memtables_at.*',
      } ->
      file_line { 'Config File Remove 4':
        path => $cassandra_config_file,
        line => "#reduce_cache_sizes_at",
        match   => '^reduce_cache_sizes_at.*',
      } ->
      file_line { 'Config File Remove 5':
        path => $cassandra_config_file,
        line => "#reduce_cache_capacity_to",
        match   => '^reduce_cache_capacity_to.*',
      } ->
      file_line { 'Config File Remove 6':
        path => $cassandra_config_file,
        line => "#memtable_flush_queue_size",
        match   => '^memtable_flush_queue_size.*',
      } ->
      file_line { 'Config File Remove 7':
        path => $cassandra_config_file,
        line => "#tombstone_debug_threshold",
        match   => '^tombstone_debug_threshold.*',
      } ->
      file_line { 'Config File Remove 8':
        path => $cassandra_config_file,
        line => "#in_memory_compaction_limit_in_mb:",
        match   => '^in_memory_compaction_limit_in_mb:.*',
      } ->
      file_line { 'Config File Remove 9':
        path => $cassandra_config_file,
        line => "#compaction_preheat_key_cache",
        match   => '^compaction_preheat_key_cache.*',
      } ->
      file_line { 'Config File Remove 10':
        path => $cassandra_config_file,
        line => "#preheat_kernel_page_cache",
        match   => '^preheat_kernel_page_cache.*',
      } ->
      file_line { 'ENV Cassandra file setting':
        path => $cassandra_env_file,
        line => 'JVM_OPTS="$JVM_OPTS -Xss512k"',
        match   => 'JVM_OPTS=\"\$JVM_OPTS -Xss.*\"',
      } ->
      exec { 'update-jamm':
        command => "sed -i -e 's/lib\/jamm-0.2.5.jar/lib\/jamm-0.3.0.jar/' $cassandra_env_file",
        provider => shell,
      }
      exec {
        'cassandra-env-update':
        command => "${jvm_version_chk}${cassandra_env_file}",
        provider => shell,
      }
}
