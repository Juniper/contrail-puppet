## This class function is used to set config for .conf files
## Example of call:
## $redis_config_file = '/etc/redis/redis.conf'
## $redis_config = { 'redis_conf' => <key, value hash> }
## contrail::lib::augeas_conf_set { 'redis_conf':
##            config_file => $redis_config_file,
##            settings_hash => $redis_config['redis_conf'],
##            lens_to_use => 'spacevars.lns', ## based on separator, whether conf file has section, etc
## }
##
define contrail::lib::augeas_conf_set(
          $settings_hash,
          $config_file,
          $lens_to_use,
)
{
       $keys_list = keys($settings_hash)
       $key_and_values = join_keys_to_values($settings_hash, " \"")
       $prefix = prefix($key_and_values, "set ")
       $change_set = suffix($prefix, "\"")
       augeas {"${config_file}_setting_${title}":
               incl => "${config_file}",
               lens => "${lens_to_use}",
               context => "/files${config_file}",
               changes => $change_set,
       }
}
