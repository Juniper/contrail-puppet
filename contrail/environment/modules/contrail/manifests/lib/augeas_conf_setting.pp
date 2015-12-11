## This class function is used to set config for .conf files
## Example of call:
## $redis_config_file = '/etc/redis/redis.conf'
## $redis_config = { 'redis_conf' => { 'requirepass' => $redis_password;}}
##
## settings { $redis_conf_keys:
##            config_file => $redis_config_file,
##            settings_hash => $redis_config['redis_conf'],
## }
##
define contrail::lib::augeas_conf_setting(
          $key = $title,
          $settings_hash,
          $config_file,
          $lens_to_use,
)
{
        $value = $settings_hash[$key]
        augeas {"${config_file}_setting_${key}":
               incl => "${config_file}",
               lens => "${lens_to_use}",
               context => "/files${config_file}",
               changes => "set ${key} \"${value}\"",
               onlyif => "match ${key} not_include ${value}",
        }
}
